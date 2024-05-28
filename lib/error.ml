type zfs_error =
  | EzfsActivePool
  | EzfsActiveSpare
  | EzfsAshiftMismatch
  | EzfsBadBackup
  | EzfsBadCache
  | EzfsBadDev
  | EzfsBadPath
  | EzfsBadPerm
  | EzfsBadPermSet
  | EzfsBadProp
  | EzfsBadRestore
  | EzfsBadStream
  | EzfsBadTarget
  | EzfsBadType
  | EzfsBadVersion
  | EzfsBadWho
  | EzfsBusy
  | EzfsCheckpointExists
  | EzfsCksum
  | EzfsCrosstarget
  | EzfsCryptoFailed
  | EzfsDevOverflow
  | EzfsDevRmInProgress
  | EzfsDiff
  | EzfsDiffData
  | EzfsDiscardingCheckpoint
  | EzfsDsReadonly
  | EzfsErrorScrubPaused
  | EzfsErrorScrubbing
  | EzfsExists
  | EzfsExportInProgress
  | EzfsFault
  | EzfsInitializing
  | EzfsIntr
  | EzfsInvalConfig
  | EzfsInvalidName
  | EzfsIo
  | EzfsIocNotSupported
  | EzfsIsL2Cache
  | EzfsIsSpare
  | EzfsLabelFailed
  | EzfsMountFailed
  | EzfsNameTooLong
  | EzfsNoCap
  | EzfsNoCheckpoint
  | EzfsNoDelegation
  | EzfsNoDevice
  | EzfsNoEnt
  | EzfsNoHistory
  | EzfsNoInitialize
  | EzfsNoMem
  | EzfsNoPending
  | EzfsNoReplicas
  | EzfsNoResilverDefer
  | EzfsNoScrub
  | EzfsNoSpc
  | EzfsNoTrim
  | EzfsNotSup
  | EzfsNotUserNamespace
  | EzfsOpenFailed
  | EzfsPerm
  | EzfsPipeFailed
  | EzfsPoolInvalArg
  | EzfsPoolNotSup
  | EzfsPoolProps
  | EzfsPoolReadonly
  | EzfsPoolUnavail
  | EzfsPostSplitOnline
  | EzfsPropNoninherit
  | EzfsPropReadonly
  | EzfsPropSpace
  | EzfsPropType
  | EzfsRaidzExpandInProgress
  | EzfsRebuilding
  | EzfsRecursive
  | EzfsReftagHold
  | EzfsReftagRele
  | EzfsResilvering
  | EzfsResumeExists
  | EzfsScrubPaused
  | EzfsScrubPausedToCancel
  | EzfsScrubbing
  | EzfsShareFailed
  | EzfsShareNfsFailed
  | EzfsShareSmbFailed
  | EzfsTagTooLong
  | EzfsThreadCreateFailed
  | EzfsTooMany
  | EzfsTrimNotSup
  | EzfsTrimming
  | EzfsUmountFailed
  | EzfsUnknown
  | EzfsUnplayedLogs
  | EzfsUnshareNfsFailed
  | EzfsUnshareSmbFailed
  | EzfsVdevNotSup
  | EzfsVdevNotSup1
  | EzfsVdevTooBig
  | EzfsVolTooBig
  | EzfsWrongParent
  | EzfsZoned

let to_int = function
  | EzfsActivePool -> 2074
  | EzfsActiveSpare -> 2057
  | EzfsAshiftMismatch -> 2099
  | EzfsBadBackup -> 2015
  | EzfsBadCache -> 2053
  | EzfsBadDev -> 2018
  | EzfsBadPath -> 2024
  | EzfsBadPerm -> 2048
  | EzfsBadPermSet -> 2049
  | EzfsBadProp -> 2001
  | EzfsBadRestore -> 2014
  | EzfsBadStream -> 2010
  | EzfsBadTarget -> 2016
  | EzfsBadType -> 2006
  | EzfsBadVersion -> 2021
  | EzfsBadWho -> 2047
  | EzfsBusy -> 2007
  | EzfsCheckpointExists -> 2077
  | EzfsCksum -> 2095
  | EzfsCrosstarget -> 2025
  | EzfsCryptoFailed -> 2075
  | EzfsDevOverflow -> 2023
  | EzfsDevRmInProgress -> 2080
  | EzfsDiff -> 2069
  | EzfsDiffData -> 2070
  | EzfsDiscardingCheckpoint -> 2078
  | EzfsDsReadonly -> 2011
  | EzfsErrorScrubPaused -> 2067
  | EzfsErrorScrubbing -> 2066
  | EzfsExists -> 2008
  | EzfsExportInProgress -> 2091
  | EzfsFault -> 2033
  | EzfsInitializing -> 2084
  | EzfsIntr -> 2035
  | EzfsInvalConfig -> 2037
  | EzfsInvalidName -> 2013
  | EzfsIo -> 2034
  | EzfsIocNotSupported -> 2082
  | EzfsIsL2Cache -> 2054
  | EzfsIsSpare -> 2036
  | EzfsLabelFailed -> 2046
  | EzfsMountFailed -> 2027
  | EzfsNameTooLong -> 2043
  | EzfsNoCap -> 2045
  | EzfsNoCheckpoint -> 2079
  | EzfsNoDelegation -> 2050
  | EzfsNoDevice -> 2017
  | EzfsNoEnt -> 2009
  | EzfsNoHistory -> 2039
  | EzfsNoInitialize -> 2085
  | EzfsNoMem -> 2000
  | EzfsNoPending -> 2076
  | EzfsNoReplicas -> 2019
  | EzfsNoResilverDefer -> 2090
  | EzfsNoScrub -> 2068
  | EzfsNoSpc -> 2032
  | EzfsNoTrim -> 2088
  | EzfsNotSup -> 2056
  | EzfsNotUserNamespace -> 2094
  | EzfsOpenFailed -> 2044
  | EzfsPerm -> 2031
  | EzfsPipeFailed -> 2062
  | EzfsPoolInvalArg -> 2042
  | EzfsPoolNotSup -> 2041
  | EzfsPoolProps -> 2040
  | EzfsPoolReadonly -> 2071
  | EzfsPoolUnavail -> 2022
  | EzfsPostSplitOnline -> 2064
  | EzfsPropNoninherit -> 2004
  | EzfsPropReadonly -> 2002
  | EzfsPropSpace -> 2005
  | EzfsPropType -> 2003
  | EzfsRaidzExpandInProgress -> 2098
  | EzfsRebuilding -> 2092
  | EzfsRecursive -> 2038
  | EzfsReftagHold -> 2060
  | EzfsReftagRele -> 2059
  | EzfsResilvering -> 2020
  | EzfsResumeExists -> 2096
  | EzfsScrubPaused -> 2072
  | EzfsScrubPausedToCancel -> 2073
  | EzfsScrubbing -> 2065
  | EzfsShareFailed -> 2097
  | EzfsShareNfsFailed -> 2030
  | EzfsShareSmbFailed -> 2052
  | EzfsTagTooLong -> 2061
  | EzfsThreadCreateFailed -> 2063
  | EzfsTooMany -> 2083
  | EzfsTrimNotSup -> 2089
  | EzfsTrimming -> 2087
  | EzfsUmountFailed -> 2028
  | EzfsUnknown -> 2100
  | EzfsUnplayedLogs -> 2058
  | EzfsUnshareNfsFailed -> 2029
  | EzfsUnshareSmbFailed -> 2051
  | EzfsVdevNotSup -> 2055
  | EzfsVdevNotSup1 -> 2093
  | EzfsVdevTooBig -> 2081
  | EzfsVolTooBig -> 2012
  | EzfsWrongParent -> 2086
  | EzfsZoned -> 2026

let of_int_opt = function
  | 0 -> None
  | 2000 -> Some EzfsNoMem
  | 2001 -> Some EzfsBadProp
  | 2002 -> Some EzfsPropReadonly
  | 2003 -> Some EzfsPropType
  | 2004 -> Some EzfsPropNoninherit
  | 2005 -> Some EzfsPropSpace
  | 2006 -> Some EzfsBadType
  | 2007 -> Some EzfsBusy
  | 2008 -> Some EzfsExists
  | 2009 -> Some EzfsNoEnt
  | 2010 -> Some EzfsBadStream
  | 2011 -> Some EzfsDsReadonly
  | 2012 -> Some EzfsVolTooBig
  | 2013 -> Some EzfsInvalidName
  | 2014 -> Some EzfsBadRestore
  | 2015 -> Some EzfsBadBackup
  | 2016 -> Some EzfsBadTarget
  | 2017 -> Some EzfsNoDevice
  | 2018 -> Some EzfsBadDev
  | 2019 -> Some EzfsNoReplicas
  | 2020 -> Some EzfsResilvering
  | 2021 -> Some EzfsBadVersion
  | 2022 -> Some EzfsPoolUnavail
  | 2023 -> Some EzfsDevOverflow
  | 2024 -> Some EzfsBadPath
  | 2025 -> Some EzfsCrosstarget
  | 2026 -> Some EzfsZoned
  | 2027 -> Some EzfsMountFailed
  | 2028 -> Some EzfsUmountFailed
  | 2029 -> Some EzfsUnshareNfsFailed
  | 2030 -> Some EzfsShareNfsFailed
  | 2031 -> Some EzfsPerm
  | 2032 -> Some EzfsNoSpc
  | 2033 -> Some EzfsFault
  | 2034 -> Some EzfsIo
  | 2035 -> Some EzfsIntr
  | 2036 -> Some EzfsIsSpare
  | 2037 -> Some EzfsInvalConfig
  | 2038 -> Some EzfsRecursive
  | 2039 -> Some EzfsNoHistory
  | 2040 -> Some EzfsPoolProps
  | 2041 -> Some EzfsPoolNotSup
  | 2042 -> Some EzfsPoolInvalArg
  | 2043 -> Some EzfsNameTooLong
  | 2044 -> Some EzfsOpenFailed
  | 2045 -> Some EzfsNoCap
  | 2046 -> Some EzfsLabelFailed
  | 2047 -> Some EzfsBadWho
  | 2048 -> Some EzfsBadPerm
  | 2049 -> Some EzfsBadPermSet
  | 2050 -> Some EzfsNoDelegation
  | 2051 -> Some EzfsUnshareSmbFailed
  | 2052 -> Some EzfsShareSmbFailed
  | 2053 -> Some EzfsBadCache
  | 2054 -> Some EzfsIsL2Cache
  | 2055 -> Some EzfsVdevNotSup
  | 2056 -> Some EzfsNotSup
  | 2057 -> Some EzfsActiveSpare
  | 2058 -> Some EzfsUnplayedLogs
  | 2059 -> Some EzfsReftagRele
  | 2060 -> Some EzfsReftagHold
  | 2061 -> Some EzfsTagTooLong
  | 2062 -> Some EzfsPipeFailed
  | 2063 -> Some EzfsThreadCreateFailed
  | 2064 -> Some EzfsPostSplitOnline
  | 2065 -> Some EzfsScrubbing
  | 2066 -> Some EzfsErrorScrubbing
  | 2067 -> Some EzfsErrorScrubPaused
  | 2068 -> Some EzfsNoScrub
  | 2069 -> Some EzfsDiff
  | 2070 -> Some EzfsDiffData
  | 2071 -> Some EzfsPoolReadonly
  | 2072 -> Some EzfsScrubPaused
  | 2073 -> Some EzfsScrubPausedToCancel
  | 2074 -> Some EzfsActivePool
  | 2075 -> Some EzfsCryptoFailed
  | 2076 -> Some EzfsNoPending
  | 2077 -> Some EzfsCheckpointExists
  | 2078 -> Some EzfsDiscardingCheckpoint
  | 2079 -> Some EzfsNoCheckpoint
  | 2080 -> Some EzfsDevRmInProgress
  | 2081 -> Some EzfsVdevTooBig
  | 2082 -> Some EzfsIocNotSupported
  | 2083 -> Some EzfsTooMany
  | 2084 -> Some EzfsInitializing
  | 2085 -> Some EzfsNoInitialize
  | 2086 -> Some EzfsWrongParent
  | 2087 -> Some EzfsTrimming
  | 2088 -> Some EzfsNoTrim
  | 2089 -> Some EzfsTrimNotSup
  | 2090 -> Some EzfsNoResilverDefer
  | 2091 -> Some EzfsExportInProgress
  | 2092 -> Some EzfsRebuilding
  | 2093 -> Some EzfsVdevNotSup1
  | 2094 -> Some EzfsNotUserNamespace
  | 2095 -> Some EzfsCksum
  | 2096 -> Some EzfsResumeExists
  | 2097 -> Some EzfsShareFailed
  | 2098 -> Some EzfsRaidzExpandInProgress
  | 2099 -> Some EzfsAshiftMismatch
  | _ -> Some EzfsUnknown

let to_string = function
  | EzfsActivePool -> "pool is imported on a different host"
  | EzfsActiveSpare -> "pool has active shared spare device"
  | EzfsAshiftMismatch ->
      "adding devices with different physical sector sizes is not allowed"
  | EzfsBadBackup -> "backup failed"
  | EzfsBadCache -> "invalid or missing cache file"
  | EzfsBadDev -> "invalid device"
  | EzfsBadPath -> "must be an absolute path"
  | EzfsBadPerm -> "invalid permission"
  | EzfsBadPermSet -> "invalid permission set name"
  | EzfsBadProp -> "invalid property value"
  | EzfsBadRestore -> "unable to restore to destination"
  | EzfsBadStream -> "invalid backup stream"
  | EzfsBadTarget -> "invalid target vdev"
  | EzfsBadType -> "operation not applicable to datasets of this type"
  | EzfsBadVersion -> "unsupported version or feature"
  | EzfsBadWho -> "invalid user/group"
  | EzfsBusy -> "pool or dataset is busy"
  | EzfsCheckpointExists -> "checkpoint exists"
  | EzfsCksum -> "insufficient replicas"
  | EzfsCrosstarget -> "operation crosses datasets or pools"
  | EzfsCryptoFailed -> "encryption failure"
  | EzfsDevOverflow -> "too many devices in one vdev"
  | EzfsDevRmInProgress -> "device removal in progress"
  | EzfsDiff -> "unable to generate diffs"
  | EzfsDiffData -> "invalid diff data"
  | EzfsDiscardingCheckpoint -> "currently discarding checkpoint"
  | EzfsDsReadonly -> "dataset is read-only"
  | EzfsErrorScrubPaused -> "error scrub is paused"
  | EzfsErrorScrubbing -> "currently error scrubbing"
  | EzfsExists -> "pool or dataset exists"
  | EzfsExportInProgress -> "pool export in progress"
  | EzfsFault -> "bad address"
  | EzfsInitializing -> "currently initializing"
  | EzfsIntr -> "signal received"
  | EzfsInvalConfig -> "invalid vdev configuration"
  | EzfsInvalidName -> "invalid name"
  | EzfsIo -> "I/O error"
  | EzfsIocNotSupported -> "operation not supported by zfs kernel module"
  | EzfsIsL2Cache -> "device is in use as a cache"
  | EzfsIsSpare -> "device is reserved as a hot spare"
  | EzfsLabelFailed -> "write of label failed"
  | EzfsMountFailed -> "mount failed"
  | EzfsNameTooLong -> "dataset name is too long"
  | EzfsNoCap -> "disk capacity information could not be retrieved"
  | EzfsNoCheckpoint -> "checkpoint does not exist"
  | EzfsNoDelegation -> "delegated administration is disabled on pool"
  | EzfsNoDevice -> "no such device in pool"
  | EzfsNoEnt -> "no such pool or dataset"
  | EzfsNoHistory -> "no history available"
  | EzfsNoInitialize -> "there is no active initialization"
  | EzfsNoMem -> "out of memory"
  | EzfsNoPending -> "operation is not in progress"
  | EzfsNoReplicas -> "no valid replicas"
  | EzfsNoResilverDefer -> "this action requires the resilver_defer feature"
  | EzfsNoScrub -> "there is no active scrub"
  | EzfsNoSpc -> "out of space"
  | EzfsNoTrim -> "there is no active trim"
  | EzfsNotSup -> "operation not supported on this dataset"
  | EzfsNotUserNamespace -> "the provided file was not a user namespace file"
  | EzfsOpenFailed -> "open failed"
  | EzfsPerm -> "permission denied"
  | EzfsPipeFailed -> "pipe create failed"
  | EzfsPoolInvalArg -> "invalid argument for this pool operation"
  | EzfsPoolNotSup -> "operation not supported on this type of pool"
  | EzfsPoolProps -> "failed to retrieve pool properties"
  | EzfsPoolReadonly -> "pool is read-only"
  | EzfsPoolUnavail -> "pool is unavailable"
  | EzfsPostSplitOnline -> "disk was split from this pool into a new one"
  | EzfsPropNoninherit -> "property cannot be inherited"
  | EzfsPropReadonly -> "read-only property"
  | EzfsPropSpace -> "invalid quota or reservation"
  | EzfsPropType -> "property doesn't apply to datasets of this type"
  | EzfsRaidzExpandInProgress -> "raidz expansion in progress"
  | EzfsRebuilding -> "currently sequentially resilvering"
  | EzfsRecursive -> "recursive dataset dependency"
  | EzfsReftagHold -> "tag already exists on this dataset"
  | EzfsReftagRele -> "no such tag on this dataset"
  | EzfsResilvering -> "currently resilvering"
  | EzfsResumeExists -> "resuming recv on existing dataset without force"
  | EzfsScrubPaused -> "scrub is paused"
  | EzfsScrubPausedToCancel -> "scrub is paused but cancelable"
  | EzfsScrubbing -> "currently scrubbing"
  | EzfsShareFailed -> "share failed"
  | EzfsShareNfsFailed -> "NFS share creation failed"
  | EzfsShareSmbFailed -> "SMB share creation failed"
  | EzfsTagTooLong -> "tag too long"
  | EzfsThreadCreateFailed -> "thread create failed"
  | EzfsTooMany -> "argument list too long"
  | EzfsTrimNotSup -> "trim operations are not supported by this device"
  | EzfsTrimming -> "currently trimming"
  | EzfsUmountFailed -> "unmount failed"
  | EzfsUnknown -> "unknown error"
  | EzfsUnplayedLogs -> "log device has unplayed intent logs"
  | EzfsUnshareNfsFailed -> "NFS share removal failed"
  | EzfsUnshareSmbFailed -> "SMB share removal failed"
  | EzfsVdevNotSup -> "vdev specification is not supported"
  | EzfsVdevNotSup1 -> "operation not supported on this type of vdev"
  | EzfsVdevTooBig -> "device exceeds supported size"
  | EzfsVolTooBig -> "volume size exceeds limits for this system"
  | EzfsWrongParent -> "invalid parent dataset"
  | EzfsZoned -> "dataset in use by local zone"

type zfs_errno =
  | ZfsErrAshiftMismatch
  | ZfsErrBadProp
  | ZfsErrBookmarkSourceNotAncestor
  | ZfsErrCheckpointExists
  | ZfsErrCryptoNotSup
  | ZfsErrDevRmInProgress
  | ZfsErrDiscardingCheckpoint
  | ZfsErrExportInProgress
  | ZfsErrFromIvsetGuidMismatch
  | ZfsErrFromIvsetGuidMissing
  | ZfsErrIocArgBadType
  | ZfsErrIocArgRequired
  | ZfsErrIocArgUnavail
  | ZfsErrIocCmdUnavail
  | ZfsErrNoCheckpoint
  | ZfsErrNotUserNamespace
  | ZfsErrRaidzExpandInProgress
  | ZfsErrRebuildInProgress
  | ZfsErrResilverInProgress
  | ZfsErrResumeExists
  | ZfsErrSpillBlockFlagMissing
  | ZfsErrStreamLargeBlockMismatch
  | ZfsErrStreamTruncated
  | ZfsErrUnknownSendStreamFeature
  | ZfsErrVdevNotSup
  | ZfsErrVdevTooBig
  | ZfsErrWrongParent

let zfs_errno_to_int = function
  | ZfsErrAshiftMismatch -> 1050
  | ZfsErrBadProp -> 1044
  | ZfsErrBookmarkSourceNotAncestor -> 1039
  | ZfsErrCheckpointExists -> 1024
  | ZfsErrCryptoNotSup -> 1048
  | ZfsErrDevRmInProgress -> 1027
  | ZfsErrDiscardingCheckpoint -> 1025
  | ZfsErrExportInProgress -> 1038
  | ZfsErrFromIvsetGuidMismatch -> 1035
  | ZfsErrFromIvsetGuidMissing -> 1034
  | ZfsErrIocArgBadType -> 1032
  | ZfsErrIocArgRequired -> 1031
  | ZfsErrIocArgUnavail -> 1030
  | ZfsErrIocCmdUnavail -> 1029
  | ZfsErrNoCheckpoint -> 1026
  | ZfsErrNotUserNamespace -> 1046
  | ZfsErrRaidzExpandInProgress -> 1049
  | ZfsErrRebuildInProgress -> 1043
  | ZfsErrResilverInProgress -> 1042
  | ZfsErrResumeExists -> 1047
  | ZfsErrSpillBlockFlagMissing -> 1036
  | ZfsErrStreamLargeBlockMismatch -> 1041
  | ZfsErrStreamTruncated -> 1040
  | ZfsErrUnknownSendStreamFeature -> 1037
  | ZfsErrVdevNotSup -> 1045
  | ZfsErrVdevTooBig -> 1028
  | ZfsErrWrongParent -> 1033

let zfs_errno_of_int_opt = function
  | 1024 -> Some ZfsErrCheckpointExists
  | 1025 -> Some ZfsErrDiscardingCheckpoint
  | 1026 -> Some ZfsErrNoCheckpoint
  | 1027 -> Some ZfsErrDevRmInProgress
  | 1028 -> Some ZfsErrVdevTooBig
  | 1029 -> Some ZfsErrIocCmdUnavail
  | 1030 -> Some ZfsErrIocArgUnavail
  | 1031 -> Some ZfsErrIocArgRequired
  | 1032 -> Some ZfsErrIocArgBadType
  | 1033 -> Some ZfsErrWrongParent
  | 1034 -> Some ZfsErrFromIvsetGuidMissing
  | 1035 -> Some ZfsErrFromIvsetGuidMismatch
  | 1036 -> Some ZfsErrSpillBlockFlagMissing
  | 1037 -> Some ZfsErrUnknownSendStreamFeature
  | 1038 -> Some ZfsErrExportInProgress
  | 1039 -> Some ZfsErrBookmarkSourceNotAncestor
  | 1040 -> Some ZfsErrStreamTruncated
  | 1041 -> Some ZfsErrStreamLargeBlockMismatch
  | 1042 -> Some ZfsErrResilverInProgress
  | 1043 -> Some ZfsErrRebuildInProgress
  | 1044 -> Some ZfsErrBadProp
  | 1045 -> Some ZfsErrVdevNotSup
  | 1046 -> Some ZfsErrNotUserNamespace
  | 1047 -> Some ZfsErrResumeExists
  | 1048 -> Some ZfsErrCryptoNotSup
  | 1049 -> Some ZfsErrRaidzExpandInProgress
  | 1050 -> Some ZfsErrAshiftMismatch
  | _ -> None

let zfs_common_error = function
  | Unix.EFAULT -> Some EzfsFault
  | Unix.EINTR -> Some EzfsIntr
  | Unix.EIO -> Some EzfsIo
  | Unix.EPERM | Unix.EACCES -> Some EzfsPerm
  | Unix.EUNKNOWNERR 85 (* ECANCELED *) -> Some EzfsNoDelegation
  | Unix.EUNKNOWNERR 97 (* EINTEGRITY (ECKSUM) *) -> Some EzfsCksum
  | _ -> None

let zpool_standard_error errno =
  let error_info =
    match zfs_common_error errno with
    | Some ezfs -> (ezfs, None)
    | None -> (
        match errno with
        | Unix.ENODEV -> (EzfsNoDevice, None)
        | Unix.ENOENT -> (EzfsNoEnt, None)
        | Unix.EEXIST -> (EzfsExists, Some "pool already exists")
        | Unix.EBUSY -> (EzfsBusy, Some "pool is busy")
        | Unix.EUNKNOWNERR 85 (* ECANCELED (ENOTACTIVE) *) ->
            (EzfsNoPending, None)
        | Unix.ENXIO ->
            (EzfsBadDev, Some "one or more devices is currently unavailable")
        | Unix.ENAMETOOLONG -> (EzfsDevOverflow, None)
        | Unix.EOPNOTSUPP -> (EzfsPoolNotSup, None)
        | Unix.EINVAL -> (EzfsPoolInvalArg, None)
        | Unix.ENOSPC | Unix.EUNKNOWNERR 69 (* EDQUOT *) -> (EzfsNoSpc, None)
        | Unix.EAGAIN ->
            (EzfsPoolUnavail, Some "pool I/O is currently suspended")
        | Unix.EROFS -> (EzfsPoolReadonly, None)
        | Unix.EDOM ->
            (EzfsBadProp, Some "block size out of range or does not match")
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrCheckpointExists ->
            (EzfsCheckpointExists, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrDiscardingCheckpoint ->
            (EzfsDiscardingCheckpoint, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrNoCheckpoint ->
            (EzfsNoCheckpoint, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrDevRmInProgress ->
            (EzfsDevRmInProgress, None)
        | Unix.EUNKNOWNERR errno when errno = zfs_errno_to_int ZfsErrVdevTooBig
          ->
            (EzfsVdevTooBig, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrExportInProgress ->
            (EzfsExportInProgress, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrResilverInProgress ->
            (EzfsResilvering, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrRebuildInProgress ->
            (EzfsRebuilding, None)
        | Unix.EUNKNOWNERR errno when errno = zfs_errno_to_int ZfsErrBadProp ->
            (EzfsBadProp, None)
        | Unix.EUNKNOWNERR errno when errno = zfs_errno_to_int ZfsErrVdevNotSup
          ->
            (EzfsVdevNotSup1, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrIocCmdUnavail ->
            ( EzfsIocNotSupported,
              Some "the loaded zfs module does not support this operation" )
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrIocArgUnavail ->
            ( EzfsIocNotSupported,
              Some
                "the loaded zfs module does not support an option for this \
                 operation" )
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrIocArgRequired ->
            (EzfsIocNotSupported, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrIocArgBadType ->
            (EzfsIocNotSupported, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrRaidzExpandInProgress ->
            (EzfsRaidzExpandInProgress, None)
        | Unix.EUNKNOWNERR errno
          when errno = zfs_errno_to_int ZfsErrAshiftMismatch ->
            (EzfsAshiftMismatch, None)
        | _ -> (EzfsUnknown, Some (Unix.error_message errno)))
  in
  match error_info with e, Some msg -> (e, msg) | e, None -> (e, to_string e)
