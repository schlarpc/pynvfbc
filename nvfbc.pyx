from libc.stdlib cimport malloc, free, calloc
from libc.stdint cimport uint32_t, int64_t, uint8_t

import types

NVFBC_DLL_VERSION = 0x61
DEFAULT_CREATE_PRIVATE_DATA = (0x0d7bc620, 0x4c17e142, 0x5e6b5997, 0x4b5a855b)
NVFBC_TO_SYS = 0x1204

cdef get_nvfbc_struct_version(struct_size, version):
    return <uint32_t>(struct_size | ((version) << 16) | (NVFBC_DLL_VERSION << 24))



cdef extern from "Windows.h":
    ctypedef Py_UNICODE WCHAR
    ctypedef void* HANDLE
    ctypedef HANDLE HINSTANCE
    ctypedef HINSTANCE HMODULE
    ctypedef const WCHAR* LPCWSTR
    ctypedef const char* LPCSTR
    ctypedef void* FARPROC # uhhh
    HMODULE __stdcall LoadLibraryW(LPCWSTR lpFileName)
    FARPROC __stdcall GetProcAddress(HMODULE hModule, LPCSTR lpProcName)

cdef enum NVFBCRESULT
    NVFBC_SUCCESS = 0,
    NVFBC_ERROR_GENERIC = -1 # Unexpected failure in NVFBC.
    NVFBC_ERROR_INVALID_PARAM = -2 # One or more of the paramteres passed to NvFBC are invalid [This include NULL pointers].
    NVFBC_ERROR_INVALIDATED_SESSION = -3 # NvFBC session is invalid. Client needs to recreate session.
    NVFBC_ERROR_PROTECTED_CONTENT = -4 # Protected content detected. Capture failed.
    NVFBC_ERROR_DRIVER_FAILURE = -5 # GPU driver returned failure to process NvFBC command.
    NVFBC_ERROR_CUDA_FAILURE   = -6 # CUDA driver returned failure to process NvFBC command.
    NVFBC_ERROR_UNSUPPORTED    = -7 # API Unsupported on this version of NvFBC.
    NVFBC_ERROR_HW_ENC_FAILURE  = -8 # HW Encoder returned failure to process NVFBC command.
    NVFBC_ERROR_INCOMPATIBLE_DRIVER = -9 # NVFBC is not compatible with this version of the GPU driver.
    NVFBC_ERROR_UNSUPPORTED_PLATFORM = -10 # NVFBC is not supported on this platform.
    NVFBC_ERROR_OUT_OF_MEMORY  = -11, # Failed to allocate memory.
    NVFBC_ERROR_INVALID_PTR    = -12 #  A NULL pointer was passed.
    NVFBC_ERROR_INCOMPATIBLE_VERSION = -13 # An API was called with a parameter struct that has an incompatible version. Check dwVersion field of paramter struct.
    NVFBC_ERROR_OPT_CAPTURE_FAILURE = -14 # Desktop Capture failed.
    NVFBC_ERROR_INSUFFICIENT_PRIVILEGES  = -15 # User doesn't have appropriate previlages.
    NVFBC_ERROR_INVALID_CALL = -16 # NVFBC APIs called in wrong sequence.
    NVFBC_ERROR_SYSTEM_ERROR = -17 # Win32 error.
    NVFBC_ERROR_INVALID_TARGET = -18 # The target adapter idx can not be used for NVFBC capture. It may not correspond to an NVIDIA GPU, or may not be attached to desktop.
    NVFBC_ERROR_NVAPI_FAILURE = -19 # NvAPI Error
    NVFBC_ERROR_DYNAMIC_DISABLE = -20 # NvFBC is dynamically disabled. Cannot continue to capture

cdef struct NvFBCStatusEx:
    uint32_t version           # [in]  Struct version. Set to NVFBC_STATUS_VER.
    uint32_t flags             # [out] Bit 0 (is_capture_possible): Indicates if NvFBC feature is
                               #       enabled.
                               # [out] Bit 1 (currently_capturing): Indicates if NVFBC is currently
                               #       capturing for the Adapter ordinal specified in adapter_idx.
                               # [out] Bit 2 (can_create_now): Deprecated. Do not use.
                               # [out] Bit 3 (support_multi_head) MultiHead grab supported.
                               # [out] Bit 4 (support_configurable_difference_map): 16x16, 32x32,
                               #       64x64 and 128x128 difference map supported.
                               # [in]  Bit 5-31 (reserved_bits): Reserved, do not use.
    uint32_t nvfbc_version     # [out] Indicates the highest NvFBC interface version supported by
                               #       the loaded NVFBC library.
    uint32_t adapter_idx       # [in]  Adapter Ordinal corresponding to the display to be grabbed.
                               #       IGNORED if bCapturePID is set.
    void*    private_data      # [in]  optional
    uint32_t private_data_size # [in]  optional
    uint32_t reserved_int[59]  # [in]  Reserved. Should be set to 0.
    void*    reserved_ptr[31]  # [in]  Reserved. Should be set to NULL.
# NvFBCStatusEx._defaults_ = {
    # 'version': get_nvfbc_struct_version(NvFBCStatusEx, 2),
# }

cdef struct NvFBCCreateParams:
    uint32_t        version             # [in]  Struct version. Set to NVFBC_CREATE_PARAMS_VER.
    uint32_t        interface_type      # [in]  ID of the NVFBC interface Type being requested.
    uint32_t        max_display_width   # [out] Max. display width allowed.
    uint32_t        max_display_height  # [out] Max. display height allowed.
    void*           device              # [in]  Device pointer.
    void*           private_data        # [in]  Private data [optional].
    uint32_t        private_data_size   # [in]  Size of private data.
    uint32_t        interface_version   # [in]  Version of the capture interface.
    INvFBCToSys_v3* nvfbc               # [out] A pointer to the requested NVFBC object.
    uint32_t        adapter_idx         # [in]  Adapter Ordinal corresponding to the display to be
                                        #       grabbed. If device is set, this parameter is
                                        #       ignored.
    uint32_t        nvfbc_version       # [out] Indicates the highest NvFBC interface version
                                        #       supported by the loaded NVFBC library.
    void*           cuda_ctx            # [in]  CUDA context created using cuD3D9CtxCreate with the
                                        #       D3D9 device passed as device. Only used for
                                        #       NvFBCCuda interface. It is mandatory to pass a valid
                                        #       D3D9 device if cuda_ctx is passed. The call will
                                        #       fail otherwise. Client must release NvFBCCuda object
                                        #       before destroying the cuda_ctx.
    void*    private_data_2             # [in]  Private data [optional].
    uint32_t private_data_2_size        # [in]  Size of private data.
    uint32_t reserved_int[55]           # [in]  Reserved. Should be set to 0.
    void*    reserved_ptr[27]           # [in]  Reserved. Should be set to NULL.

cdef cppclass INvFBCToSys_v3:
    int __stdcall NvFBCToSysSetUp(void*)#NVFBC_TOSYS_SETUP_PARAMS_V2*)
    int __stdcall NvFBCToSysGrabFrame(void*)#NVFBC_TOSYS_GRAB_FRAME_PARAMS*)
    int __stdcall NvFBCToSysCursorCapture(void*)#NVFBC_CURSOR_CAPTURE_PARAMS*)
    int __stdcall NvFBCToSysGPUBasedCPUSleep(int64_t)
    int __stdcall NvFBCToSysRelease()

cdef struct NVFBC_TOSYS_SETUP_PARAMS_V2:
    uint32_t version            # [in]  Struct version. Set to NVFBC_TOSYS_SETUP_PARAMS_VER.
    uint32_t flags              # [in]  Bit 0 (with_hw_cursor): The client should set this to 1 if
                                #       it requires the HW cursor to be composited on the captured
                                #       image.
                                # [in]  Bit 1 (diff_map): The client should set this to use the
                                #       DiffMap feature.
                                # [in]  Bit 2 (enable_seperate_cursor_capture): The client should
                                #       set this to 1 if it wants to enable mouse capture in
                                #       separate stream.
                                # [in]  Bit 3 (hdr_request): The client should set this to 1 to
                                #       request HDR capture.
                                # [in]  Bit 4-6 (diff_map_block_size): Valid only if bDiffMap is
                                #       set. Set this bit field using enum
                                #       NVFBC_TOSYS_DIFFMAP_BLOCKSIZE. Default blocksize is 128x128
                                # [in]  Bit 7-31 (reserved_bits): Reserved. Set to 0.
    NVFBCToSysBufferFormat mode # [in]  Output image format.
    uint32_t reserved_1         # [in]  Reserved. Set to 0.
    void** buffer               # [out] Container to hold NvFBC output buffers.
    void** diff_map             # [out] Container to hold NvFBC output diffmap buffers.
    void* cursor_capture_event  # [out] Client should wait for mouseEventHandle event before
                                #       calling MouseGrab function.
    uint32_t reserved_int[58]   # [in]  Reserved. Set to 0.
    void* reserved_ptr[29]      # [in]  Reserved. Set to 0.

ctypedef int (*NvFBC_GetStatusExFunctionType)(NvFBCStatusEx*)
ctypedef int (*NvFBC_CreateExFunctionType)(NvFBCCreateParams*)


class NvFBCException(Exception):
    pass

cdef class NvFBC:
    cdef HMODULE _nvfbc_library
    cdef NvFBC_GetStatusExFunctionType _get_status_ex
    cdef NvFBC_CreateExFunctionType _create_ex

    def __init__(self):
        self._nvfbc_library = LoadLibraryW(u'NvFBC64.dll')
        self._get_status_ex = <NvFBC_GetStatusExFunctionType>GetProcAddress(
            self._nvfbc_library,
            'NvFBC_GetStatusEx',
        )
        self._create_ex = <NvFBC_CreateExFunctionType>GetProcAddress(
            self._nvfbc_library,
            'NvFBC_CreateEx',
        )

    cpdef _call_get_status_ex(self):
        cdef NvFBCStatusEx status = NvFBCStatusEx(
            version=get_nvfbc_struct_version(sizeof(NvFBCStatusEx), 2),
        )
        cdef int error = self._get_status_ex(&status)
        if error != 0:
            raise NvFBCException(error)
        return types.SimpleNamespace(
            flags=status.flags,
            nvfbc_version=status.nvfbc_version,
        )

    @property
    def runtime_version(self):
        return self._call_get_status_ex().nvfbc_version

    @property
    def is_capture_possible(self):
        return bool(self._call_get_status_ex().flags & 0b00001)

    @property
    def currently_capturing(self):
        return bool(self._call_get_status_ex().flags & 0b00010)

    @property
    def can_create_now(self):
        return bool(self._call_get_status_ex().flags & 0b00100)

    @property
    def support_multi_head(self):
        return bool(self._call_get_status_ex().flags & 0b01000)

    @property
    def support_configurable_difference_map(self):
        return bool(self._call_get_status_ex().flags & 0b10000)

    @property
    def library_version(self):
        return NVFBC_DLL_VERSION



# wat = NvFBC_GetStatusEx(&status_request)
# print('Return:', wat)
# print('Flags:', status_request.flags)

# print(nvfbc)