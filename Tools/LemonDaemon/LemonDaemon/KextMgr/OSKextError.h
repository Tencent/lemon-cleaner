//
//  OSKextError.h
//  McFireWallCtl
//

//  Copyright (c) 2011 Magican Software Ltd. All rights reserved.
//

#ifndef McFireWallCtl_OSKextError_h
#define McFireWallCtl_OSKextError_h


#define sub_libkern_kext           err_sub(2)
#define libkern_kext_err(code)     (sys_libkern|sub_libkern_kext|(code))


/*!
 * @define   kOSKextReturnInternalError
 * @abstract An internal error in the kext library.
 *           Contrast with <code>@link //apple_ref/c/econst/OSReturnError
 *           OSReturnError@/link</code>.
 */
#define kOSKextReturnInternalError                   libkern_kext_err(0x1)

/*!
 * @define   kOSKextReturnNoMemory
 * @abstract Memory allocation failed.
 */
#define kOSKextReturnNoMemory                        libkern_kext_err(0x2)

/*!
 * @define   kOSKextReturnNoResources
 * @abstract Some resource other than memory (such as available load tags)
 *           is exhausted.
 */
#define kOSKextReturnNoResources                     libkern_kext_err(0x3)

/*!
 * @define   kOSKextReturnNotPrivileged
 * @abstract The caller lacks privileges to perform the requested operation.
 */
#define kOSKextReturnNotPrivileged                   libkern_kext_err(0x4)

/*!
 * @define   kOSKextReturnInvalidArgument
 * @abstract Invalid argument.
 */
#define kOSKextReturnInvalidArgument                 libkern_kext_err(0x5)

/*!
 * @define   kOSKextReturnNotFound
 * @abstract Search item not found.
 */
#define kOSKextReturnNotFound                        libkern_kext_err(0x6)

/*!
 * @define   kOSKextReturnBadData
 * @abstract Malformed data (not used for XML).
 */
#define kOSKextReturnBadData                         libkern_kext_err(0x7)

/*!
 * @define   kOSKextReturnSerialization
 * @abstract Error converting or (un)serializing URL, string, or XML.
 */
#define kOSKextReturnSerialization                   libkern_kext_err(0x8)

/*!
 * @define   kOSKextReturnUnsupported
 * @abstract Operation is no longer or not yet supported.
 */
#define kOSKextReturnUnsupported                     libkern_kext_err(0x9)

/*!
 * @define   kOSKextReturnDisabled
 * @abstract Operation is currently disabled.
 */
#define kOSKextReturnDisabled                        libkern_kext_err(0xa)

/*!
 * @define   kOSKextReturnNotAKext
 * @abstract Bundle is not a kernel extension.
 */
#define kOSKextReturnNotAKext                        libkern_kext_err(0xb)

/*!
 * @define   kOSKextReturnValidation
 * @abstract Validation failures encountered; check diagnostics for details.
 */
#define kOSKextReturnValidation                      libkern_kext_err(0xc)

/*!
 * @define   kOSKextReturnAuthentication
 * @abstract Authetication failures encountered; check diagnostics for details.
 */
#define kOSKextReturnAuthentication                  libkern_kext_err(0xd)

/*!
 * @define   kOSKextReturnDependencies
 * @abstract Dependency resolution failures encountered; check diagnostics for details.
 */
#define kOSKextReturnDependencies                    libkern_kext_err(0xe)

/*!
 * @define   kOSKextReturnArchNotFound
 * @abstract Kext does not contain code for the requested architecture.
 */
#define kOSKextReturnArchNotFound                    libkern_kext_err(0xf)

/*!
 * @define   kOSKextReturnCache
 * @abstract An error occurred processing a system kext cache.
 */
#define kOSKextReturnCache                           libkern_kext_err(0x10)

/*!
 * @define   kOSKextReturnDeferred
 * @abstract Operation has been posted asynchronously to user space (kernel only).
 */
#define kOSKextReturnDeferred                        libkern_kext_err(0x11)

/*!
 * @define   kOSKextReturnBootLevel
 * @abstract Kext not loadable or operation not allowed at current boot level.
 */
#define kOSKextReturnBootLevel                       libkern_kext_err(0x12)

/*!
 * @define   kOSKextReturnNotLoadable
 * @abstract Kext cannot be loaded; check diagnostics for details.
 */
#define kOSKextReturnNotLoadable                     libkern_kext_err(0x13)

/*!
 * @define   kOSKextReturnLoadedVersionDiffers
 * @abstract A different version (or executable UUID, or executable by checksum)
 *           of the requested kext is already loaded.
 */
#define kOSKextReturnLoadedVersionDiffers            libkern_kext_err(0x14)

/*!
 * @define   kOSKextReturnDependencyLoadError
 * @abstract A load error occurred on a dependency of the kext being loaded.
 */
#define kOSKextReturnDependencyLoadError             libkern_kext_err(0x15)

/*!
 * @define   kOSKextReturnLinkError
 * @abstract A link failure occured with this kext or a dependency.
 */
#define kOSKextReturnLinkError                       libkern_kext_err(0x16)

/*!
 * @define   kOSKextReturnStartStopError
 * @abstract The kext start or stop routine returned an error.
 */
#define kOSKextReturnStartStopError                  libkern_kext_err(0x17)

/*!
 * @define   kOSKextReturnInUse
 * @abstract The kext is currently in use or has outstanding references,
 *           and cannot be unloaded.
 */
#define kOSKextReturnInUse                           libkern_kext_err(0x18)

/*!
 * @define   kOSKextReturnTimeout
 * @abstract A kext request has timed out.
 */
#define kOSKextReturnTimeout                         libkern_kext_err(0x19)

/*!
 * @define   kOSKextReturnStopping
 * @abstract The kext is in the process of stopping; requests cannot be made.
 */
#define kOSKextReturnStopping                        libkern_kext_err(0x1a)


#endif
