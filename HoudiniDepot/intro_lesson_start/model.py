from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from hutil.Qt import QtCore
from hutil.Qt import QtGui
from hutil.Qt.QtCore import Qt

import hou
import husd
import _houqt
import hdefereval
import toolutils
import re
import sys
import itertools
import usdprimicons
import dbg

from pxr import Usd, UsdGeom

from edit import common

ICON_SIZE = hou.ui.scaledSize(16)

SELECT_ICON = hou.qt.createIcon(
                        "TOOLS_select_mode_boxselect", ICON_SIZE, ICON_SIZE)
XFORM_ICON = hou.qt.createIcon("SOP_xform", ICON_SIZE, ICON_SIZE)
CHECKMARK_ICON = hou.qt.createIcon("MISC_checkmark", ICON_SIZE, ICON_SIZE)
PHYSEXPLICIT_ICON = hou.qt.createIcon("MISC_checkmark", ICON_SIZE, ICON_SIZE)
PHYSCHILD_ICON = hou.qt.createIcon("MISC_installed", ICON_SIZE, ICON_SIZE)
ERROR_ICON = hou.qt.createIcon("NETVIEW_error_badge", ICON_SIZE, ICON_SIZE)
SCOPE_ICON = hou.qt.createIcon(
        "SCENEGRAPH_primtype_scope", ICON_SIZE, ICON_SIZE)

PHYS_ICON = hou.qt.createIcon("PARTS_rbd", ICON_SIZE, ICON_SIZE)
BYPASS_ICON = hou.qt.createIcon("NETVIEW_bypass_flag", ICON_SIZE, ICON_SIZE)
T_ICON = hou.qt.createIcon("BUTTONS_translate", ICON_SIZE, ICON_SIZE)
R_ICON = hou.qt.createIcon("BUTTONS_rotate", ICON_SIZE, ICON_SIZE)
S_ICON = hou.qt.createIcon("BUTTONS_scale", ICON_SIZE, ICON_SIZE)

XTYPE_ICONS = (T_ICON, R_ICON, S_ICON)

ICON_EDIT_SUFFIX = "_edit"
ICON_SELECTION_SUFFIX = "_selected"

_iconcache = {}

DeltaXformRole = Qt.UserRole + 1
WorldXformRole = Qt.UserRole + 2
PathRole = Qt.UserRole + 3
PhysicsRole = Qt.UserRole + 4
SelectionRole = Qt.UserRole + 5
BypassRole = Qt.UserRole + 6
IsInstanceRole = Qt.UserRole + 7
XformCompCleanRole = Qt.UserRole + 10
XformAxisDisplayRole = Qt.UserRole + 20  # reserve 10..18
XformAxisEditRole = Qt.UserRole + 30  # reserve 20..28

Translate = 0
Rotate = 1
Scale = 2

X = 0
Y = 1
Z = 2

Local = 0
World = 1

abs_tol = (1e-5, 1e-5, 0.0)
rel_tol = (1e-5, 1e-5, 1e-5)
none_val = (0.0, 0.0, 1.0)


def _cachedQtIcon(iconname):
    icon = _iconcache.get(iconname, None)

    if icon is not None:
        return icon

    icon = hou.qt.createIcon(iconname, ICON_SIZE, ICON_SIZE)

    _iconcache[iconname] = icon

    return icon


def _primIconName(prim):
    return usdprimicons.getIconForPrim(prim)


def _atoi(text):
    return int(text) if text.isdigit() else text


def _editsort(path):
    groups = [_atoi(c) for c in re.split(r'(\d+)', path)]
    return groups


# from python 3.5
def _isclose(a, b, rel_tol=1e-09, abs_tol=0.0):
    return abs(a-b) <= max(rel_tol * max(abs(a), abs(b)), abs_tol)


def _visclose(vec_a, scalar_b, rel_tol, abs_tol):
    for comp in vec_a:
        if not _isclose(comp, scalar_b, rel_tol=rel_tol, abs_tol=abs_tol):
            return False
    return True


def _isCompClean(values, comp):
    return _visclose(values,
                     none_val[comp],
                     abs_tol=abs_tol[comp],
                     rel_tol=rel_tol[comp])


def _floatrepr(fval):
    return "{:.6}".format(fval)


def _extractCompValues(xform, comp):
    if comp == Translate:
        return xform.extractTranslates()
    elif comp == Rotate:
        return xform.extractRotates()
    elif comp == Scale:
        return xform.extractScales()


def _getUsdPrimChildren(prim, primfilter):
    children = None
    if prim.IsInstance():
        children = [prim.GetChild(masterchild.GetName())
                    for masterchild in prim.GetPrototype().GetChildren()]
    else:
        children = prim.GetChildren()

    if primfilter is not None:
        children = filter(primfilter, children)

        # filter() returns an iterator in Python 3
        # but callers of this function expect a list.
        if sys.version_info.major >= 3:
            children = list(children)

    return children


class EditItem(_houqt.QT_LopXformItem):
    def __init__(self, itemid):
        super(EditItem, self).__init__()

        self._itemid = itemid

        self._prim = None

        # The clean state of each transform component (t/r/s)
        # i.e. True means the component is at its default, False means it's
        # been modified.
        #
        # None indicates that the component hasn't been cached.
        self._compclean = [None, None, None]

    #############
    # Overrides #
    #############

    def __eq__(self, other):
        return self._itemid == other._itemid

    def __ne__(self, other):
        return not self.__eq__(other)

    def fetchMore(self):
        remainingchildren = self._childPrims[self.rowCount():]

        assert self.fetchMoreCount() == len(remainingchildren)

        for prim in remainingchildren:
            self.model()._fetchItemForPrim(self, prim)

        self.setFetchMoreCount(0)

        self.model().itemCountChanged.emit(self.model()._nextitemid)

    def canFetchMore(self):
        return self.fetchMoreCount() > 0

    def cacheXformAxisValuesIfNeeded(self):
        """ Called by the C++ base class if xform axis data is not yet
            cached in user roles.
        """

        if self._compclean[Translate] is None:
            self._cacheComponent(Translate)

        if self._compclean[Rotate] is None:
            self._cacheComponent(Rotate)

        if self._compclean[Scale] is None:
            self._cacheComponent(Scale)

    ##################
    # Public methods #
    ##################

    def parentOrRoot(self):
        parent = self.parent()

        if parent is not None:
            return parent

        return self.model().invisibleRootItem()

    def prepareFetch(self):
        self._childPrims = self.model()._getFetchablePrims(self)
        self.setFetchMoreCount(len(self._childPrims))

    def setXformComponentAxis(self, comp, axis, value):
        if self.model()._xformspace == World:
            xform = self.data(WorldXformRole)
        else:
            xform = self.data(DeltaXformRole)
        if xform is not None:
            xform = hou.Matrix4(xform)
            t = xform.extractTranslates()
            r = xform.extractRotates()
            s = xform.extractScales()
        else:
            t = hou.Vector3(0, 0, 0)
            r = hou.Vector3(0, 0, 0)
            s = hou.Vector3(1, 1, 1)

        [t, r, s][comp][axis] = value

        xform = hou.hmath.buildScale(s) \
            * hou.hmath.buildRotate(r) \
            * hou.hmath.buildTranslate(t)

        self._setXform(xform)

        self._clearXformComponentCache(comp)

    def xformCompClean(self, comp):
        if self._compclean[comp] is None:
            self._cacheComponent(comp)

        return self._compclean[comp]

    ###################
    # Private methods #
    ###################

    def _setXform(self, xform):
        path = self.data(PathRole)

        if self.model()._xformspace == World:
            self.setData(xform.asTuple(), WorldXformRole)

            basexform = common.getXformWithAncestorDeltas(
                    self.model().stage(), path,
                    self.model()._deltapointdict, self.model()._parentcache,
                    opname=self.model()._sourcenode.name())
            xform = xform * basexform.inverted()

        # We need to store the data as a tuple so that
        # it can be pickled for drag and drop.
        self.setData(xform.asTuple(), DeltaXformRole)

    def _cacheComponent(self, comp):
        """ Sets a bunch of data that can be retrieved by the C++ base class
            using standard data() calls.
        """

        noval = False

        xformspace = self.model()._xformspace
        if xformspace == World:
            worldxform = self.data(WorldXformRole)
            if worldxform is None:
                path = self.data(PathRole)
                worldxform = self.model().getWorldXform(path)
                self.setData(worldxform.asTuple(), WorldXformRole)
            else:
                worldxform = hou.Matrix4(worldxform)

        localxform = self.data(DeltaXformRole)

        # use localxform values to check clean state
        if localxform is None:
            noval = True
        else:
            localxform = hou.Matrix4(localxform)
            compvalues = _extractCompValues(localxform, comp)

            noval = _isCompClean(compvalues, comp)

        self._compclean[comp] = noval

        values = [None, None, None]
        dispvalues = [None, None, None]

        if xformspace == Local and noval:
            values[comp] = [none_val[comp],
                            none_val[comp],
                            none_val[comp]]

            dispvalues[comp] = \
                [_floatrepr(none_val[comp]) for i in range(3)]

        else:
            if xformspace == World:
                # if in world space, get the world display values
                compvalues = _extractCompValues(worldxform, comp)

            values[comp] = compvalues

            dispvalues[comp] = [_floatrepr(v) for v in compvalues]

        for axis in range(3):
            role = XformAxisDisplayRole + 3 * comp + axis
            self.setData(dispvalues[comp][axis], role)

            role = XformAxisEditRole + 3 * comp + axis
            self.setData(values[comp][axis], role)

        self.setData(self._compclean[comp], XformCompCleanRole + comp)

    def _clearXformComponentCache(self, comp):
        # our main indicator that we haven't cached a component
        self._compclean[comp] = None

        # xform axis roles are checked for isNull() by the C++ base class,
        # so reset those as well.
        self.setData(None, XformCompCleanRole + comp)

        for axis in range(3):
            role = XformAxisDisplayRole + 3 * comp + axis
            role = XformAxisEditRole + 3 * comp + axis
            self.setData(None, role)

    def _clearXformCache(self):
        self.setData(None, WorldXformRole)

        self._clearXformComponentCache(Translate)
        self._clearXformComponentCache(Rotate)
        self._clearXformComponentCache(Scale)


class EditModel(_houqt.QT_LopXformItemModel):
    nodeStateChanged = QtCore.Signal()
    nodeSelectionChanged = QtCore.Signal()
    itemAboutToBeCondensed = QtCore.Signal(EditItem)
    itemCondensed = QtCore.Signal(EditItem)
    itemCountChanged = QtCore.Signal(int)

    theNodeCallbackEvents = [
        hou.nodeEventType.BeingDeleted,
        hou.nodeEventType.FlagChanged,
        hou.nodeEventType.InputDataChanged,
        hou.nodeEventType.InputRewired,
        hou.nodeEventType.ParmTupleChanged,
    ]

    theXformParmTupleNames = [
        "t",
        "r",
        "s",
        "shear",
        "scale",
    ]

    theColumnLabels = [
        None,
        None,
        "tx",
        "ty",
        "tz",
        "rx",
        "ry",
        "rz",
        "sx",
        "sy",
        "sz",
        None,
        None,
        None,
        None,
    ]

    PathCol = 0
    PhysicsCol = 1
    txCol = 2
    tyCol = 3
    tzCol = 4
    rxCol = 5
    ryCol = 6
    rzCol = 7
    sxCol = 8
    syCol = 9
    szCol = 10
    HasTranslateCol = 11
    HasRotateCol = 12
    HasScaleCol = 13
    BypassCol = 14

    DisplayModeFlatList = 0
    DisplayModeCondensedTree = 1
    DisplayModeFullTree = 2

    _clearXformTypeUndoLabels = (
        "Clear Translates",
        "Clear Rotates",
        "Clear Scales",
    )

    PhysStateDisabled = 0
    PhysStateEnabled = 1
    PhysStateChild = 2

    #############
    # Overrides #
    #############

    def __init__(self, parent=None):
        super(EditModel, self).__init__(parent)

        self._stage = None
        self._nextitemid = 0
        self._primpathtoitem = dict()
        self._primfilter = None
        self._sourcenode = None
        self._stage = None

        # whether the node was valid on the last updateFromNode call
        # used to check whether the valid state changes, which emits
        # the nodeStateChanged signal
        self._sourcenodevalid = None

        self._queuedupdatefromnode = False
        self._displayMode = self.DisplayModeFlatList
        self._xformspace = Local

        self._font = QtGui.QFont()
        self._font.setFamily("Source Code Pro")
        self._font.setPixelSize(12)

        self._batchitems = None

        self._physicsprims = set()

        self._bypassprims = set()

        self._addallprims = True
        self._primstofetch = set()
        self._ancestorstofetch = set()
        self._primstoshow = []
        self._useexplicitprims = False

    def columnCount(self, parent=QtCore.QModelIndex()):
        return len(EditModel.theColumnLabels)

    def setShowExplicitPrims(self, value):
        self._useexplicitprims = bool(value)
        if value:
            self.setAddAllPrims(False)

    def _addPrimToShow(self, primpath):
        if primpath not in self._primstoshow:
            self._primstoshow.append(primpath)
            if self._displayMode > self.DisplayModeFlatList:
                names = primpath.split('/')[1:-1]

                pathpart = ""
                for name in names:
                    pathpart += "/" + name

                    if not self._addallprims:
                        self._ancestorstofetch.add(pathpart)

    def addPrimToShow(self, primpath):
        self._addPrimToShow(primpath)
        self.updateFromNode()

    def removePrimToShow(self, primpath):
        dbg.trace(primpath)
        self._primstoshow.remove(primpath)
        self.updateFromNode()

    def setPrimsToShow(self, primpaths):
        if primpaths == self._primstoshow:
            return
        oldprimstoshow = list(self._primstoshow)
        self._primstoshow = []
        for primpath in primpaths:
            if husd.utils.isCollectionPath(primpath):
                if self.sourceNodeValid():
                    subprimpaths = husd.utils.pathsInCollectionAt(
                        self._sourcenode.stage(), primpath)
                    if subprimpaths is not None:
                        for subprimpath in subprimpaths:
                            self._addPrimToShow(str(subprimpath))
            else:
                self._addPrimToShow(primpath)
        if oldprimstoshow == self._primstoshow:
            return
        self.updateFromNode()

    def primsToShow(self):
        return list(self._primstoshow)

    def headerData(self, section, orientation, role):
        if role == Qt.DisplayRole:
            labels = EditModel.theColumnLabels
            if section >= len(labels):
                return None
            return labels[section]

        elif role == Qt.DecorationRole:
            if section == EditModel.PhysicsCol:
                return PHYS_ICON

            if section == EditModel.BypassCol:
                return BYPASS_ICON

            xtype = section - EditModel.HasTranslateCol
            if xtype >= Translate and xtype <= Scale:
                return XTYPE_ICONS[xtype]

        elif role == Qt.ToolTipRole:
            if section == EditModel.PhysicsCol:
                return "Has Physics Enabled"

            if section == EditModel.HasTranslateCol:
                return "Was Translated"

            if section == EditModel.HasRotateCol:
                return "Was Rotated"

            if section == EditModel.HasScaleCol:
                return "Was Scaled"

    def beginBatchXformEdit(self):
        self._batchitems = []

    def endBatchXformEdit(self):
        deltaparm = self._sourcenode.parm("delta")

        editpaths = []

        for item in self._batchitems:
            path = item.data(PathRole)
            editpaths.append(path)

        self._removeNodeCallbacks()
        self._bypassprims = common.removePathsFromPattern(
            self._sourcenode,
            self._sourcenode.parm("bypassprimpattern"),
            editpaths,
            includesdescendants=False)
        self._addNodeCallbacks()

        self._updateBypassStates(self._batchitems)

        deltageo = deltaparm.eval()

        if deltageo is None:
            deltageo = common.makeDeltaGeo()
        else:
            deltageo = deltageo.freeze()

        for item in self._batchitems:
            path = item.data(PathRole)
            xform = item.data(DeltaXformRole)

            globpoints = deltageo.globPoints("@primpath==" + path)

            if len(globpoints) > 0:
                point = globpoints[0]
            else:
                point = deltageo.createPoint()
                point.setAttribValue("primpath", path)

            point.setAttribValue("xform", xform)

        with hou.undos.group("Edit Transform Values"):
            deltaparm.set(deltageo)

        self._batchitems = None

        # TO DO clear only touched items.
        self._parentcache = {}

    def setData(self, index, value, role):
        if role == Qt.EditRole:
            if self._batchitems is None:
                raise Exception("beginBatchXormEdit() wasn't called")

            mainindex = self.index(index.row(), 0, index.parent())
            mainitem = self.itemFromIndex(mainindex)

            self._batchitems.append(mainitem)

            i = index.column() - self.txCol
            comp = i // 3
            axis = i % 3

            mainitem.setXformComponentAxis(comp, axis, value)

            return True

        return super(EditModel, self).setData(index, value, role)

    ##################
    # Public methods #
    ##################

    def setPrimFilter(self, primfilter):
        self._primfilter = primfilter

    def setStage(self, stage):
        self._stage = stage

    def stage(self):
        return self._stage

    def primpathToItem(self, primpath):
        return self._primpathtoitem.get(primpath, None)

    def mainItemFromIndex(self, index):
        mainindex = self.index(index.row(), 0, index.parent())
        return self.itemFromIndex(mainindex)

    def itemAndDescendants(self, item, includeself=True, fetch=True):
        if includeself:
            yield item
        if fetch and isinstance(item, EditItem) and \
                item.canFetchMore():
            item.fetchMore()
        for i in range(item.rowCount()):
            childitem = item.child(i)
            for subitem in self.itemAndDescendants(childitem, fetch=fetch):
                yield subitem

    def previousItems(self, startitem):
        """
            Iterates over items preceding startitem in reverse linear order.

            Calls fetchMore() on traversed items.
        """
        current = startitem
        while True:
            myrow = current.row()

            if not isinstance(current, EditItem):
                break

            parent = current.parentOrRoot()

            # iterate over previous children in reverse order
            for i in range(myrow-1, -1, -1):
                for subitem in reversed(list(
                        self.itemAndDescendants(parent.child(i)))):
                    yield subitem

            if isinstance(parent, EditItem):
                yield parent

            current = parent

    def nextItems(self, startitem):
        """
            Iterates over items following startitem in linear order.

            Calls fetchMore() on traversed items.
        """
        for subitem in self.itemAndDescendants(startitem, includeself=False):
            yield subitem
        current = startitem
        while True:
            myrow = current.row()

            if not isinstance(current, EditItem):
                break

            parent = current.parentOrRoot()

            for i in range(myrow+1, parent.rowCount()):
                for subitem in self.itemAndDescendants(parent.child(i)):
                    yield subitem
            current = parent

    def lastItem(self, startitem):
        """
            Returns the last item in linear order.

            Only calls fetchMore() on last child of each item.
        """
        if isinstance(startitem, EditItem) and \
                startitem.canFetchMore():
            startitem.fetchMore()

        childcount = startitem.rowCount()

        if childcount == 0:
            return startitem

        lastchild = startitem.child(childcount - 1)

        return self.lastItem(lastchild)

    def itemsAndDescendants(self, items, fetch=True):
        for item in items:
            for subitem in self.itemAndDescendants(item, fetch=fetch):
                yield subitem

    def indexesAndDescendants(self, indexes):
        map_func = \
            map if sys.version_info.major >= 3 else itertools.imap
        items = map_func(self.itemFromIndex, indexes)
        for item in self.itemsAndDescendants(items):
            yield self.indexFromItem(item)

    def clear(self):
        super(EditModel, self).clear()

        self._primpathtoitem.clear()

    def fetchMore(self, index):
        if not index.isValid():
            root = self.invisibleRootItem()

            if root.rowCount():
                return

            if self._stage is None:
                return

            for prim in self._getFetchablePrims(root):
                self._fetchItemForPrim(root, prim)

            return

        item = self.itemFromIndex(index)

        item.fetchMore()

    def _makeItem(self, path, label):
        itemid = self._nextitemid
        self._nextitemid = itemid + 1

        item = EditItem(itemid)

        item.setData(path, PathRole)
        item.setText(label)

        item.setEditable(False)

        # don't add actual items for columns. much faster to override
        # the model's data method and fetch data off a single item per row
        item.setColumnCount(len(self.theColumnLabels))

        xform = None
        point = self._deltapointdict.get(path, None)
        if point is not None:
            xform = hou.Matrix4(point.attribValue("xform"))
            item.setData(xform.asTuple(), DeltaXformRole)

        # Set the icon unless this is an instance.
        if self.stage() is None:
            item.setIcon(ERROR_ICON)
        elif path.find('[') == -1:
            prim = self.stage().GetPrimAtPath(path)
            if prim.IsValid():
                iconname = _primIconName(prim)
                item.setIcon(_cachedQtIcon(iconname))
            else:
                item.setIcon(ERROR_ICON)

        item.setData(self._getPhysicsStateFromPath(path), PhysicsRole)

        item.setData(self._getBypassStateFromPath(path), BypassRole)

        item.setData(False, IsInstanceRole)

        return item

    def setAddAllPrims(self, enabled):
        enabled = enabled and not self._useexplicitprims
        self._addallprims = enabled

        if enabled:
            self.setPrimFilter(
                lambda p: bool(UsdGeom.Xformable(p)))

        else:
            self.setPrimFilter(
                lambda p: bool(UsdGeom.Xformable(p)) and
                (str(p.GetPrimPath()) in self._primstofetch or
                 str(p.GetPrimPath()) in self._ancestorstofetch))

    def primIsKind(self, prim, primkind):
        modelapi = Usd.ModelAPI(prim)

        return modelapi.GetKind() == primkind

    def primHasChildOfKind(self, prim, primkind):
        primrange = Usd.PrimRange(prim, Usd.TraverseInstanceProxies())
        childiter = iter(primrange)

        # skip self
        childiter.next()

        for child in childiter:
            if self.primIsKind(child, primkind):
                return True
        else:
            return False

    def dataOrColumnDefault(self, index, role):
        column = index.column()
        if column < EditModel.txCol or column > EditModel.szCol:
            raise ValueError("No default for column {}".format(column))

        value = self.data(index, role)

        if value is not None:
            return value

        comp = (column - self.txCol) // 3
        return none_val[comp]

    def xformCompForColumn(self, column):
        if column >= self.txCol and \
                column <= self.szCol:
            return (column - self.txCol) // 3

        elif column >= self.HasTranslateCol and \
                column <= self.HasScaleCol:
            return column - self.HasTranslateCol
        else:
            return None

    def sourceNodeValid(self):
        try:
            return self._sourcenode is not None and \
                isinstance(self._sourcenode, hou.LopNode) and \
                self._sourcenode.stage() is not None
        except:
            return False

    def setXformSpace(self, space):
        self._xformspace = space

        return self.invisibleRootItem()

    def getWorldXform(self, path):
        return common.getXformWithDeltas(
                self.stage(), path, self._deltapointdict, self._parentcache,
                opname=self._sourcenode.name())

    def _updateDeltaXforms(self):
        # get the data for the paths we will show
        deltageo = self._sourcenode.evalParm("delta")
        # get what we were showing
        oldpaths = set()
        if self._deltapointdict:
            oldpaths = set(self._deltapointdict.keys())

        if deltageo is not None:
            self._deltapointdict = common.makeDeltaPointDict(
                deltageo,
                bypass_descriptors=self._bypassprims)

            # loop over these paths and add them to the set of prims to
            # fetch, including all ancestors.
            delta_point_dict_items = \
                self._deltapointdict.items() \
                    if sys.version_info.major >= 3 else \
                        self._deltapointdict.iteritems()
            for path, point in delta_point_dict_items:
                if not UsdGeom.Xformable(self._stage.GetPrimAtPath(path)):
                    continue

                self._primstofetch.add(path)

                # if We're not showing a flat list then add each ancestor
                # to our list of prims to fetch
                if self._displayMode > self.DisplayModeFlatList:
                    names = path.split('/')[1:-1]

                    pathpart = ""
                    for name in names:
                        pathpart += "/" + name

                        if not self._addallprims:
                            self._ancestorstofetch.add(pathpart)
        else:
            self._deltapointdict = dict()
            self._parentcache = dict()
            delta_point_dict_items = []


        # Determine which paths we were showing that won't be shown anymore.
        oldpaths.difference_update(self._deltapointdict.keys())

        dictitems = itertools.chain(
            ([k, None] for k in oldpaths),
            delta_point_dict_items)

        # loop over all prims, removed ones first, and update its
        # transform from the delta geometry object.
        # Removed ones and those with no representation in the delta
        # geometry will have their transform set to 'None'.
        for path, point in dictitems:
            item = self.primpathToItem(path)
            if item is None:
                continue

            item._clearXformCache()

            if point is not None:
                item.setData(point.attribValue("xform"), DeltaXformRole)
            else:
                item.setData(None, DeltaXformRole)

            index = item.index()
            row = index.row()
            parent = index.parent()

            startindex = self.index(row, self.txCol, parent)
            endindex = self.index(row, self.HasScaleCol, parent)

            self.dataChanged.emit(
                startindex, endindex, [Qt.DisplayRole])

    def _updateControlledPrims(self):
        if self._useexplicitprims:
            self._updateExplicitPrims()
        else:
            self._updateDeltaXforms()

    def _updateExplicitPrims(self):
        deltageo = self._sourcenode.evalParm("delta")

        # get what we were showing
        # oldpaths = set(self._primstoshow)

        deltageo = self._sourcenode.evalParm("delta")
        if deltageo is not None:
            # get the paths we will show
            self._deltapointdict = common.makeDeltaPointDict(
                deltageo,
                bypass_descriptors=self._bypassprims)

            for path in self._primstoshow:
                if not UsdGeom.Xformable(self._stage.GetPrimAtPath(path)):
                    continue

                self._primstofetch.add(path)

                if self._displayMode > self.DisplayModeFlatList:
                    names = path.split('/')[1:-1]

                    pathpart = ""
                    for name in names:
                        pathpart += "/" + name

                        if not self._addallprims:
                            self._ancestorstofetch.add(pathpart)
        else:
            self._deltapointdict = dict()
            self._parentcache = dict()

        dictitems = [(p, self._deltapointdict.get(p)) for p in self._primstoshow]
        for path, point in dictitems:
            item = self.primpathToItem(path)
            if item is None:
                continue

            item._clearXformCache()

            if point is not None:
                xform = hou.Matrix4(point.attribValue("xform"))
            else:
                xform = hou.Matrix4(1)
            item.setData(xform.asTuple(), DeltaXformRole)

            index = item.index()
            row = index.row()
            parent = index.parent()

            startindex = self.index(row, self.txCol, parent)
            endindex = self.index(row, self.HasScaleCol, parent)

            self.dataChanged.emit(
                startindex, endindex, [Qt.DisplayRole])

    def _updateSelectionFromNode(self):
        selpaths = common.getNodeSelection(self._sourcenode)

        for selpath in selpaths:
            if selpath in self._deltapointdict:
                continue

            if not UsdGeom.Xformable(self._stage.GetPrimAtPath(selpath)):
                continue

            self._primstofetch.add(selpath)
            if self._displayMode > self.DisplayModeFlatList:
                names = selpath.split('/')[1:-1]

                pathpart = ""
                for name in names:
                    pathpart += "/" + name

                    if not self._addallprims:
                        self._ancestorstofetch.add(pathpart)

        self.nodeSelectionChanged.emit()

    def _prepareReset(self):
        self.clear()

        self._nextitemid = 0

        self._deltapointdict = dict()
        self._parentcache = dict()
        self._primstofetch = set()
        self._ancestorstofetch = set()

    def _getRootPrim(self):
        if self._stage is None:
            return None

        return self._stage.GetPseudoRoot()

    def updateFromNode(self):
        self.beginResetModel()

        newstate = self.sourceNodeValid()

        if self._sourcenodevalid != newstate:
            self._sourcenodevalid = newstate
            self.nodeStateChanged.emit()

        if self._sourcenodevalid:
            self.setStage(self._sourcenode.stage())

            self.blockSignals(True)
            self._prepareReset()
            self.blockSignals(False)

            self.invisibleRootItem().setData("", PathRole)
            self.invisibleRootItem().setColumnCount(len(self.theColumnLabels))

            self._updateControlledPrims()
            self._updateSelectionFromNode()
            self._cachePhysicsPrims()
            self._cacheBypassPrims()

        else:
            self.setStage(None)

        self.endResetModel()

    def simplifyTreeIfNeeded(self):
        if self._shouldCondenseTree():
            self._simplifyTree()

    def getSelectedPaths(self):
        if self.sourceNodeValid():
            return common.getNodeSelection(self._sourcenode)

        return []

    def getSelection(self):
        paths = self.getSelectedPaths()

        selection = QtCore.QItemSelection()

        for path in paths:
            item = self.primpathToItem(path)

            if item is None:
                continue

            index = self.indexFromItem(item)

            if not index.isValid():
                continue

            selection.select(index, index)

        return selection

    def setSelection(self, rowindexes):
        if not self._addallprims:
            for item in self.itemAndDescendants(self.invisibleRootItem()):
                index = self.indexFromItem(item)
                item.setData(item.data(DeltaXformRole) is None and
                             index in rowindexes, SelectionRole)

        paths = [self.itemFromIndex(i).data(PathRole) for i in rowindexes]

        self.setSelectedPaths(paths)

        if not self._addallprims and not self._useexplicitprims:
            self.removeOtherSelectionItems(rowindexes)

    def indexHasPhysics(self, index):
        item = self.itemFromIndex(index)
        return item.data(PhysicsRole) > self.PhysStateDisabled

    def indexIsBypassed(self, index):
        item = self.itemFromIndex(index)
        return bool(item.data(BypassRole))

    def indexIsInstance(self, index):
        item = self.itemFromIndex(index)
        return bool(item.data(IsInstanceRole))

    def setSelectedPaths(self, selectedpaths):
        if self.stage() is None:
            return

        def valid(path):
            # If the path is an instance then check that the
            # instance index is valid and that the instancer
            # is valid.
            instance_index = path.find('[')
            if instance_index != -1:
                # Find the last instance of ']', we won't support
                # nested instances at this time so the string between
                # the first [ and the last ] must be a valid integer.
                index_end_index = path.rfind(']')
                try:
                    int(path[instance_index + 1: index_end_index])
                except ValueError:
                    return False
                path = path[:instance_index]

            return self.stage().GetPrimAtPath(path).IsValid()

        selectedpaths = [p for p in selectedpaths if valid(p)]
        selectedpaths.sort(key=lambda p: _editsort(p))

        patternparm = self._sourcenode.parm("primpattern")

        with hou.undos.group("Set Selection"):

            self._removeNodeCallbacks()

            patternparm.set(" ".join(selectedpaths))

            sv = toolutils.sceneViewer()
            sv.setCurrentSceneGraphSelection(selectedpaths)

            self._addNodeCallbacks()

    def activate(self):
        try:
            self.updateFromNode()
            self._addNodeCallbacks()
        except hou.ObjectWasDeleted:
            # The node may have been deleted while we were deactivated. So
            # clear out our current node if there is any issue.
            self.setCurrentNode(None)
        except:
            # We probably shouldn't hide other exceptions yet.
            raise

    def deactivate(self):
        self._removeNodeCallbacks()

    def setCurrentNode(self, node):
        if isinstance(node, hou.LopNode) and \
           node.type().name() in ('edit', 'lightmixer', 'layout'):
            newnode = node

        else:
            # Some other node type set or explicit request for None.
            # For now we assume we're only shown in the Edit LOP's parm dialog,
            # so we just set to None in either case
            newnode = None

        try:
            if self._sourcenode != newnode:
                nodechanged = True
            else:
                nodechanged = False
        except:
            nodechanged = True

        if nodechanged:
            self._removeNodeCallbacks()
            self._sourcenode = newnode
            self.updateFromNode()
            self._addNodeCallbacks()

    def getOtherSelectionItems(self, parentitem, keeprowindexes):
        """
            Returns a list of row indexes that have selection items and are
            *not* listed in keeprowindexes
        """
        other = []

        for i in range(parentitem.rowCount()):
            item = parentitem.child(i)
            if item.data(DeltaXformRole) is None:
                index = self.indexFromItem(item)
                keep = index in keeprowindexes
                if not keep:
                    other.append((item, index.row(), parentitem))

            other += self.getOtherSelectionItems(item, keeprowindexes)

        return other

    def removeOtherSelectionItems(self, keeprowindexes):
        """
            Removes rows that have selection items and are *not* listed in
            keeprowindexes
        """

        other = self.getOtherSelectionItems(
                self.invisibleRootItem(), keeprowindexes)

        # Iterate in reverse order, such that children are deleted first and
        # childCount() will already return 0 for any parent that has all
        # children deleted.
        for item, row, parentitem in reversed(other):
            if item.rowCount() == 0:
                # For some reason, the internal C++ object of the invisible
                # root can already be deleted here, so only use the parentitem
                # object if it's a EditItem, otherwise get a new
                # invisibleRootItem object.
                if isinstance(parentitem, EditItem):
                    parentitem.removeRow(row)
                else:
                    self.invisibleRootItem().removeRow(row)

    def clearEdits(self, indexes):
        map_func = \
            map if sys.version_info.major >= 3 else itertools.imap

        items = map_func(self.itemFromIndex, indexes)

        deltaparm = self._sourcenode.parm("delta")
        if deltaparm.eval() is None:
            return

        delta = deltaparm.eval().freeze()
        deltapointdict = common.makeDeltaPointDict(delta)
        with hou.undos.group("Delete Edits"):
            delpoints = []
            for item in items:
                primpath = item.data(PathRole)
                point = deltapointdict.get(primpath, None)
                if point is not None:
                    delpoints.append(point)

            if delpoints:
                delta.deletePoints(delpoints)
                deltaparm.set(delta)

                sv = toolutils.sceneViewer()
                if sv.currentState() in ("sidefx_lop_edit", "sidefx_lop_lightmixer, sidefx_lop_layout"):
                    sv.runStateCommand("updatepivot")

    def clearXformComp(self, rowindexes, xtype, axis=None):
        with hou.undos.group(self._clearXformTypeUndoLabels[xtype]):
            deltaparm = self._sourcenode.parm("delta")
            delta = deltaparm.eval().freeze()
            deltapointdict = common.makeDeltaPointDict(delta)

            points = []
            for rowindex in rowindexes:
                item = self.itemFromIndex(rowindex)
                primpath = item.data(PathRole)
                xform = item.data(DeltaXformRole)
                if xform is None:
                    continue
                xform = hou.Matrix4(xform)
                point = deltapointdict.get(primpath, None)
                if point is not None:
                    points.append(point)

            if points:
                deleters = []

                for point in points:
                    xform = hou.Matrix4(point.attribValue("xform"))
                    newxform = hou.Matrix4(1)
                    tvalues = None
                    rvalues = None
                    svalues = None
                    allclean = True

                    if xtype != Scale:
                        svalues = xform.extractScales()
                        if not _isCompClean(svalues, Scale):
                            allclean = False
                    elif xtype == Scale and axis is not None:
                        svalues = xform.extractScales()
                        svalues[axis] = 1.0
                        if not _isCompClean(svalues, Scale):
                            allclean = False

                    if xtype != Rotate:
                        rvalues = xform.extractRotates()
                        if not _isCompClean(rvalues, Rotate):
                            allclean = False
                    elif xtype == Rotate and axis is not None:
                        rvalues = xform.extractRotates()
                        rvalues[axis] = 0.0
                        if not _isCompClean(rvalues, Rotate):
                            allclean = False

                    if xtype != Translate:
                        tvalues = xform.extractTranslates()
                        if not _isCompClean(tvalues, Translate):
                            allclean = False
                    elif xtype == Translate and axis is not None:
                        tvalues = xform.extractTranslates()
                        tvalues[axis] = 0.0
                        if not _isCompClean(tvalues, Translate):
                            allclean = False

                    if allclean:
                        deleters.append(point)
                    else:
                        if xtype != Scale or axis is not None:
                            newxform *= hou.hmath.buildScale(svalues)
                        if xtype != Rotate or axis is not None:
                            newxform *= hou.hmath.buildRotate(rvalues)
                        if xtype != Translate or axis is not None:
                            newxform *= hou.hmath.buildTranslate(tvalues)

                        point.setAttribValue("xform", newxform.asTuple())

                if len(deleters) > 0:
                    delta.deletePoints(deleters)

                deltaparm.set(delta)

                sv = toolutils.sceneViewer()
                if sv.currentState() in ("sidefx_lop_edit", "sidefx_lop_lightmixer"):
                    sv.runStateCommand("updatepivot")

            return

    def setPhysics(self, rowindexes, enabled):
        items = [self.itemFromIndex(i) for i in rowindexes]
        paths = [item.data(PathRole) for item in items]

        if enabled:
            common.addPathsToPattern(
                self._sourcenode,
                self._sourcenode.parm("physprimpattern"),
                paths)
        else:
            common.removePathsFromPattern(
                self._sourcenode,
                self._sourcenode.parm("physprimpattern"),
                paths)

    def setBypass(self, rowindexes, enabled):
        items = [self.itemFromIndex(i) for i in rowindexes]
        paths = [item.data(PathRole) for item in items]

        with hou.undos.group("Change Bypass Flag"):
            if enabled:
                common.addPathsToPattern(
                    self._sourcenode,
                    self._sourcenode.parm("bypassprimpattern"),
                    paths,
                    includesdescendants=False)
            else:
                common.removePathsFromPattern(
                    self._sourcenode,
                    self._sourcenode.parm("bypassprimpattern"),
                    paths,
                    includesdescendants=False)

    def setDisplayMode(self, mode):
        self._displayMode = mode
        self.updateFromNode()

    def displayMode(self):
        return self._displayMode

    ###################
    # Private methods #
    ###################

    def _getFetchablePrims(self, item):
        if self._displayMode == self.DisplayModeFlatList:
            if isinstance(item, EditItem):
                return []
            else:
                res = []

                for path in self._primstofetch:
                    res.append(self._stage.GetPrimAtPath(path))

                # dbg.msg(res)
                return res

        if isinstance(item, EditItem):
            prim = item._prim
        else:
            prim = self._getRootPrim()

        children = _getUsdPrimChildren(prim, self._primfilter)

        if self._shouldCondenseTree():
            for i, prim in enumerate(children):
                # skip over prims with only a single child and replace them
                # with the first descendant that has more than one child.
                while True:
                    path = str(prim.GetPrimPath())
                    if path in self._primstofetch:
                        break

                    subchildren = _getUsdPrimChildren(prim, self._primfilter)

                    if len(subchildren) != 1:
                        break

                    prim = subchildren[0]
                children[i] = prim

        # dbg.msg(children)
        return children

    def _fetchItemForPrim(self, parentitem, prim):
        path = str(prim.GetPrimPath())
        if self._displayMode == self.DisplayModeFlatList:
            name = path
        elif self._shouldCondenseTree():
            name = path[len(parentitem.data(PathRole))+1:]
        else:
            name = str(prim.GetName())

        def create_item(parentitem, instance_index=None):
            item_name = name
            item_path = path
            if instance_index is not None:
                suffix = '[' + str(instance_index) + ']'
                item_name += suffix
                item_path += suffix

            item = self._makeItem(item_path, item_name)

            self._primpathtoitem[item_path] = item

            parentitem.appendRow(item)

            if instance_index is None:
                item._prim = prim

                item.prepareFetch()

            return item

        item = create_item(parentitem)

        if prim.IsA(UsdGeom.PointInstancer):
            pi = UsdGeom.PointInstancer(prim)
            for i in range(pi.GetInstanceCount()):
                instance_item = create_item(item, instance_index=i)
                instance_item.setData(True, IsInstanceRole)

    def _shouldCondenseTree(self):
        return self._displayMode == self.DisplayModeCondensedTree and \
                not self._addallprims and not self._useexplicitprims

    def _xformParmsAtDefault(self):
        for parmtuplename in self.theXformParmTupleNames:
            parmtuple = self._sourcenode.parmTuple(parmtuplename)
            if not parmtuple.isAtDefault():
                return False
        return True

    def _cachePhysicsPrims(self):
        """
            Caches the current physics prims in self._physicsprims and returns
            the set of prims that were either not in the set before or that are
            no longer in the set.
        """

        prevprims = self._physicsprims
        self._physicsprims = set(common.getNodeSelection(
            self._sourcenode, "physprimpattern", descendants=True))

        return prevprims.symmetric_difference(self._physicsprims)

    def _getPhysicsStateFromPath(self, path):
        if path in self._physicsprims:
            return self.PhysStateEnabled
        else:
            return self.PhysStateDisabled

    def _updatePhysicsStates(self, items):
        for item in items:
            path = item.data(PathRole)

            state = self._getPhysicsStateFromPath(path)

            prevstate = item.data(PhysicsRole)
            if prevstate != state:
                item.setData(state, PhysicsRole)

                colindex = self.index(
                    item.index().row(),
                    self.PhysicsCol,
                    item.index().parent())

                self.dataChanged.emit(
                    colindex, colindex, [Qt.CheckStateRole])

    def _cacheBypassPrims(self):
        prevprims = self._bypassprims

        self._bypassprims = set(common.getNodeSelection(
            self._sourcenode, "bypassprimpattern"))

        return prevprims.symmetric_difference(self._bypassprims)

    def _getBypassStateFromPath(self, path):
        if path in self._bypassprims:
            return True
        else:
            return False

    def _updateBypassStates(self, items):
        for item in items:
            path = item.data(PathRole)

            state = self._getBypassStateFromPath(path)

            prevstate = item.data(BypassRole)
            if prevstate != state:
                item.setData(state, BypassRole)

                colindex = self.index(
                    item.index().row(),
                    self.BypassCol,
                    item.index().parent())

                self.dataChanged.emit(
                    colindex, colindex, [Qt.CheckStateRole])

    def _addNodeCallbacks(self):
        try:
            if self._sourcenode:
                self._sourcenode.addEventCallback(
                    self.theNodeCallbackEvents,
                    self._onNodeCallback)
        except:
            pass

    def _removeNodeCallbacks(self):
        try:
            if self._sourcenode:
                self._sourcenode.removeEventCallback(
                    self.theNodeCallbackEvents,
                    self._onNodeCallback)
        except:
            pass

    def _updateFromNodeDeferred(self):
        self.updateFromNode()

        self._queuedupdatefromnode = False

    def _simplifyTree(self):
        keepers = filter(lambda i: self._isItemReal(i),
                         self.itemAndDescendants(self.invisibleRootItem()))

        for keeper in keepers:
            current = keeper
            while current.parent() is not None:
                parent = current.parent()

                if not self._isItemReal(parent) and parent.rowCount() == 1:
                    pparent = parent.parentOrRoot()

                    parentrow = parent.row()

                    self.itemAboutToBeCondensed.emit(current)

                    temp = parent.takeRow(current.row())
                    pparent.insertRow(parentrow+1, [temp[0]])

                    current.setText(parent.text() + "/" + current.text())

                    self._primpathtoitem.pop(parent.data(PathRole))
                    pparent.removeRow(parentrow)

                    self.itemCondensed.emit(current)
                else:
                    current = parent

    def _onNodeCallback(self, *args, **kwargs):
        event_type = kwargs["event_type"]

        do_update = False

        if event_type == hou.nodeEventType.BeingDeleted:
            self._sourcenode = None
            # We only need to send an update if there is none
            # already queued.
            do_update = not self._queuedupdatefromnode

        if event_type == hou.nodeEventType.InputDataChanged:
            do_update = not self._queuedupdatefromnode

        if event_type == hou.nodeEventType.InputRewired:
            do_update = not self._queuedupdatefromnode

        if event_type == hou.nodeEventType.ParmTupleChanged:
            if 'parm_tuple' in kwargs and kwargs['parm_tuple'] is not None:
                parmname = kwargs['parm_tuple'].name()
            else:
                parmname = ''

            if parmname == "delta" and not hou.ui.isUserInteracting():
                if self._addallprims and \
                        self._displayMode != self.DisplayModeFlatList:
                    self._updateControlledPrims()
                    return
                else:
                    do_update = not self._queuedupdatefromnode

            if parmname == "primpattern":
                if self._addallprims and \
                        self._displayMode == self.DisplayModeFullTree:
                    self._updateSelectionFromNode()
                    return
                else:
                    do_update = not self._queuedupdatefromnode

            filter_func = \
                filter if sys.version_info.major >= 3 else itertools.ifilter

            if parmname == "physprimpattern":
                changedpaths = self._cachePhysicsPrims()
                changeditems = [self.primpathToItem(p) for p in changedpaths]
                changeditems = filter_func(
                    lambda i: i is not None, changeditems)
                self._updatePhysicsStates(changeditems)
                return

            if parmname == "bypassprimpattern":
                changedpaths = self._cacheBypassPrims()
                changeditems = [self.primpathToItem(p) for p in changedpaths]
                changeditems = filter_func(
                    lambda i: i is not None, changeditems)
                self._updateBypassStates(changeditems)
                self._updateControlledPrims()
                return

        if do_update:
            self._queuedupdatefromnode = True
            hdefereval.executeDeferred(self._updateFromNodeDeferred)

    def _isItemReal(self, item):
        return item.data(DeltaXformRole) is not None or \
                item.data(SelectionRole)
