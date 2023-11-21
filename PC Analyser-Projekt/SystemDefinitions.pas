unit SystemDefinitions;

interface

uses
  Winapi.Windows, Winapi.WinSvc;

type
  TransferTestOutputStruct = packed record  //IOCTL_PCANALYS_TransferTest
    TransferTest : LongWord;
  end;

  VersionOutputStruct = packed record       //IOCTL_PCANALYS_Version
    Version, Date : LongWord;
  end;

  ReadMSRInputStruct = packed record        //IOCTL_PCANALYS_ReadMSR
    ECXReg : LongWord;
  end;

  ReadMSROutputStruct = packed record       //IOCTL_PCANALYS_ReadMSR
    EAXReg, EDXReg : LongWord;
  end;

  WriteMSRInputStruct = packed record       //IOCTL_PCANALYS_WriteMSR
    ECXReg, //MSR number
    EDXReg, //upper register content
    EAXReg  //lower register content
           : LongWord;
  end;

  ReadPCIInputStruct = packed record        //IOCTL_PCANALYS_ReadPCI
    PortNumber : LongWord;
  end;

  ReadPCIOutputStruct = packed record       //IOCTL_PCANALYS_ReadPCI
    DataBuffer : LongWord;
  end;

  WritePCIInputStruct = packed record       //IOCTL_PCANALYS_WritePCI
    PortNumber, DataBuffer : LongWord;
  end;

  WritePCIOutputStruct = packed record
    DataBuffer : LongWord;
  end;

  ReadMemXBitInputStruct = packed record    //IOCTL_PCANALYS_ReadMem8Bit
    Address : LongWord;
  end;

  ReadMem8BitOutputStruct = packed record
    Data : Byte;
  end;

  ReadMem16BitOutputStruct = packed record  //IOCTL_PCANALYS_ReadMem16Bit
    Data : Word;
  end;

  ReadMem32BitOutputStruct = packed record  //IOCTL_PCANALYS_ReadMem32Bit
    Data : LongWord;
  end;

  WriteMem8BitInputStruct = packed record   //IOCTL_PCANALYS_WriteMem8Bit
    Address : LongWord;
    Data : Byte;
  end;

  WriteMem16BitInputStruct = packed record  //IOCTL_PCANALYS_WriteMem16Bit
    Address : LongWord;
    Data : Word;
  end;

  WriteMem32BitInputStruct = packed record  //IOCTL_PCANALYS_WriteMem32Bit
    Address, Data : LongWord;
  end;

  ReadPortXBitInputStruct = packed record   //IOCTL_PCANALYS_ReadPort8Bit
    Address : LongWord;
  end;

  ReadPort8BitOutputStruct = packed record
    Data : Byte;
  end;

  ReadPort16BitOutputStruct = packed record //IOCTL_PCANALYS_ReadPort16Bit
    Data : Word;
  end;

  ReadPort32BitOutputStruct = packed record //IOCTL_PCANALYS_ReadPort32Bit
    Data : LongWord;
  end;

  WritePort8BitInputStruct = packed record  //IOCTL_PCANALYS_WritePort8Bit
    Address : LongWord;
    Data : Byte;
  end;
  WritePort16BitInputStruct = packed record //IOCTL_PCANALYS_WritePort16Bit
    Address : LongWord;
    Data : Word;
  end;
  WritePort32BitInputStruct = packed record //IOCTL_PCANALYS_WritePort32Bit
    Address, Data : LongWord;
  end;

  {$IFDEF WIN64}{$Z4}{$ENDIF}
  SYSTEM_INFORMATION_CLASS = (
    SystemBasicInformation, // q: SYSTEM_BASIC_INFORMATION
    SystemProcessorInformation, // q: SYSTEM_PROCESSOR_INFORMATION
    SystemPerformanceInformation, // q: SYSTEM_PERFORMANCE_INFORMATION
    SystemTimeOfDayInformation, // q: SYSTEM_TIMEOFDAY_INFORMATION
    SystemPathInformation, // not implemented
    SystemProcessInformation, // q: SYSTEM_PROCESS_INFORMATION
    SystemCallCountInformation, // q: SYSTEM_CALL_COUNT_INFORMATION
    SystemDeviceInformation, // q: SYSTEM_DEVICE_INFORMATION
    SystemProcessorPerformanceInformation, // q: SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION
    SystemFlagsInformation, // q: SYSTEM_FLAGS_INFORMATION
    SystemCallTimeInformation, // not implemented // 10
    SystemModuleInformation, // q: RTL_PROCESS_MODULES
    SystemLocksInformation,
    SystemStackTraceInformation,
    SystemPagedPoolInformation, // not implemented
    SystemNonPagedPoolInformation, // not implemented
    SystemHandleInformation, // q: SYSTEM_HANDLE_INFORMATION
    SystemObjectInformation, // q: SYSTEM_OBJECTTYPE_INFORMATION mixed with SYSTEM_OBJECT_INFORMATION
    SystemPageFileInformation, // q: SYSTEM_PAGEFILE_INFORMATION
    SystemVdmInstemulInformation, // q
    SystemVdmBopInformation, // not implemented // 20
    SystemFileCacheInformation, // q: SYSTEM_FILECACHE_INFORMATION; s (requires SeIncreaseQuotaPrivilege) (info for WorkingSetTypeSystemCache)
    SystemPoolTagInformation, // q: SYSTEM_POOLTAG_INFORMATION
    SystemInterruptInformation, // q: SYSTEM_INTERRUPT_INFORMATION
    SystemDpcBehaviorInformation, // q: SYSTEM_DPC_BEHAVIOR_INFORMATION; s: SYSTEM_DPC_BEHAVIOR_INFORMATION (requires SeLoadDriverPrivilege)
    SystemFullMemoryInformation, // not implemented
    SystemLoadGdiDriverInformation, // s (kernel-mode only)
    SystemUnloadGdiDriverInformation, // s (kernel-mode only)
    SystemTimeAdjustmentInformation, // q: SYSTEM_QUERY_TIME_ADJUST_INFORMATION; s: SYSTEM_SET_TIME_ADJUST_INFORMATION (requires SeSystemtimePrivilege)
    SystemSummaryMemoryInformation, // not implemented
    SystemMirrorMemoryInformation, // s (requires license value "Kernel-MemoryMirroringSupported") (requires SeShutdownPrivilege) // 30
    SystemPerformanceTraceInformation, // s
    SystemObsolete0, // not implemented
    SystemExceptionInformation, // q: SYSTEM_EXCEPTION_INFORMATION
    SystemCrashDumpStateInformation, // s (requires SeDebugPrivilege)
    SystemKernelDebuggerInformation, // q: SYSTEM_KERNEL_DEBUGGER_INFORMATION
    SystemContextSwitchInformation, // q: SYSTEM_CONTEXT_SWITCH_INFORMATION
    SystemRegistryQuotaInformation, // q: SYSTEM_REGISTRY_QUOTA_INFORMATION; s (requires SeIncreaseQuotaPrivilege)
    SystemExtendServiceTableInformation, // s (requires SeLoadDriverPrivilege) // loads win32k only
    SystemPrioritySeperation, // s (requires SeTcbPrivilege)
    SystemVerifierAddDriverInformation, // s (requires SeDebugPrivilege) // 40
    SystemVerifierRemoveDriverInformation, // s (requires SeDebugPrivilege)
    SystemProcessorIdleInformation, // q: SYSTEM_PROCESSOR_IDLE_INFORMATION
    SystemLegacyDriverInformation, // q: SYSTEM_LEGACY_DRIVER_INFORMATION
    SystemCurrentTimeZoneInformation, // q
    SystemLookasideInformation, // q: SYSTEM_LOOKASIDE_INFORMATION
    SystemTimeSlipNotification, // s (requires SeSystemtimePrivilege)
    SystemSessionCreate, // not implemented
    SystemSessionDetach, // not implemented
    SystemSessionInformation, // not implemented
    SystemRangeStartInformation, // q // 50
    SystemVerifierInformation, // q: SYSTEM_VERIFIER_INFORMATION; s (requires SeDebugPrivilege)
    SystemVerifierThunkExtend, // s (kernel-mode only)
    SystemSessionProcessInformation, // q: SYSTEM_SESSION_PROCESS_INFORMATION
    SystemLoadGdiDriverInSystemSpace, // s (kernel-mode only) (same as SystemLoadGdiDriverInformation)
    SystemNumaProcessorMap, // q
    SystemPrefetcherInformation, // q: PREFETCHER_INFORMATION; s: PREFETCHER_INFORMATION // PfSnQueryPrefetcherInformation
    SystemExtendedProcessInformation, // q: SYSTEM_PROCESS_INFORMATION
    SystemRecommendedSharedDataAlignment, // q
    SystemComPlusPackage, // q; s
    SystemNumaAvailableMemory, // 60
    SystemProcessorPowerInformation, // q: SYSTEM_PROCESSOR_POWER_INFORMATION
    SystemEmulationBasicInformation, // q
    SystemEmulationProcessorInformation,
    SystemExtendedHandleInformation, // q: SYSTEM_HANDLE_INFORMATION_EX
    SystemLostDelayedWriteInformation, // q: ULONG
    SystemBigPoolInformation, // q: SYSTEM_BIGPOOL_INFORMATION
    SystemSessionPoolTagInformation, // q: SYSTEM_SESSION_POOLTAG_INFORMATION
    SystemSessionMappedViewInformation, // q: SYSTEM_SESSION_MAPPED_VIEW_INFORMATION
    SystemHotpatchInformation, // q; s
    SystemObjectSecurityMode, // q // 70
    SystemWatchdogTimerHandler, // s (kernel-mode only)
    SystemWatchdogTimerInformation, // q (kernel-mode only); s (kernel-mode only)
    SystemLogicalProcessorInformation, // q: SYSTEM_LOGICAL_PROCESSOR_INFORMATION
    SystemWow64SharedInformationObsolete, // not implemented
    SystemRegisterFirmwareTableInformationHandler, // s (kernel-mode only)
    SystemFirmwareTableInformation, // not implemented
    SystemModuleInformationEx, // q: RTL_PROCESS_MODULE_INFORMATION_EX
    SystemVerifierTriageInformation, // not implemented
    SystemSuperfetchInformation, // q: SUPERFETCH_INFORMATION; s: SUPERFETCH_INFORMATION // PfQuerySuperfetchInformation
    SystemMemoryListInformation, // q: SYSTEM_MEMORY_LIST_INFORMATION; s: SYSTEM_MEMORY_LIST_COMMAND (requires SeProfileSingleProcessPrivilege) // 80
    SystemFileCacheInformationEx, // q: SYSTEM_FILECACHE_INFORMATION; s (requires SeIncreaseQuotaPrivilege) (same as SystemFileCacheInformation)
    SystemThreadPriorityClientIdInformation, // s: SYSTEM_THREAD_CID_PRIORITY_INFORMATION (requires SeIncreaseBasePriorityPrivilege)
    SystemProcessorIdleCycleTimeInformation, // q: SYSTEM_PROCESSOR_IDLE_CYCLE_TIME_INFORMATION[]
    SystemVerifierCancellationInformation, // not implemented // name:wow64:whNT32QuerySystemVerifierCancellationInformation
    SystemProcessorPowerInformationEx, // not implemented
    SystemRefTraceInformation, // q; s // ObQueryRefTraceInformation
    SystemSpecialPoolInformation, // q; s (requires SeDebugPrivilege) // MmSpecialPoolTag, then MmSpecialPoolCatchOverruns != 0
    SystemProcessIdInformation, // q: SYSTEM_PROCESS_ID_INFORMATION
    SystemErrorPortInformation, // s (requires SeTcbPrivilege)
    SystemBootEnvironmentInformation, // q: SYSTEM_BOOT_ENVIRONMENT_INFORMATION // 90
    SystemHypervisorInformation, // q; s (kernel-mode only)
    SystemVerifierInformationEx, // q; s
    SystemTimeZoneInformation, // s (requires SeTimeZonePrivilege)
    SystemImageFileExecutionOptionsInformation, // s: SYSTEM_IMAGE_FILE_EXECUTION_OPTIONS_INFORMATION (requires SeTcbPrivilege)
    SystemCoverageInformation, // q; s // name:wow64:whNT32QuerySystemCoverageInformation; ExpCovQueryInformation
    SystemPrefetchPatchInformation, // not implemented
    SystemVerifierFaultsInformation, // s (requires SeDebugPrivilege)
    SystemSystemPartitionInformation, // q: SYSTEM_SYSTEM_PARTITION_INFORMATION
    SystemSystemDiskInformation, // q: SYSTEM_SYSTEM_DISK_INFORMATION
    SystemProcessorPerformanceDistribution, // q: SYSTEM_PROCESSOR_PERFORMANCE_DISTRIBUTION // 100
    SystemNumaProximityNodeInformation, // q
    SystemDynamicTimeZoneInformation, // q; s (requires SeTimeZonePrivilege)
    SystemCodeIntegrityInformation, // q // SeCodeIntegrityQueryInformation
    SystemProcessorMicrocodeUpdateInformation, // s
    SystemProcessorBrandString, // q // HaliQuerySystemInformation -> HalpGetProcessorBrandString, info class 23
    SystemVirtualAddressInformation, // q: SYSTEM_VA_LIST_INFORMATION[]; s: SYSTEM_VA_LIST_INFORMATION[] (requires SeIncreaseQuotaPrivilege) // MmQuerySystemVaInformation
    SystemLogicalProcessorAndGroupInformation, // q: SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX // since WIN7 // KeQueryLogicalProcessorRelationship
    SystemProcessorCycleTimeInformation, // q: SYSTEM_PROCESSOR_CYCLE_TIME_INFORMATION[]
    SystemStoreInformation, // q; s // SmQueryStoreInformation
    SystemRegistryAppendString, // s: SYSTEM_REGISTRY_APPEND_STRING_PARAMETERS // 110
    SystemAitSamplingValue, // s: ULONG (requires SeProfileSingleProcessPrivilege)
    SystemVhdBootInformation, // q: SYSTEM_VHD_BOOT_INFORMATION
    SystemCpuQuotaInformation, // q; s // PsQueryCpuQuotaInformation
    SystemNativeBasicInformation, // not implemented
    SystemSpare1, // not implemented
    SystemLowPriorityIoInformation, // q: SYSTEM_LOW_PRIORITY_IO_INFORMATION
    SystemTpmBootEntropyInformation, // q: TPM_BOOT_ENTROPY_NT_RESULT // ExQueryTpmBootEntropyInformation
    SystemVerifierCountersInformation, // q: SYSTEM_VERIFIER_COUNTERS_INFORMATION
    SystemPagedPoolInformationEx, // q: SYSTEM_FILECACHE_INFORMATION; s (requires SeIncreaseQuotaPrivilege) (info for WorkingSetTypePagedPool)
    SystemSystemPtesInformationEx, // q: SYSTEM_FILECACHE_INFORMATION; s (requires SeIncreaseQuotaPrivilege) (info for WorkingSetTypeSystemPtes) // 120
    SystemNodeDistanceInformation, // q
    SystemAcpiAuditInformation, // q: SYSTEM_ACPI_AUDIT_INFORMATION // HaliQuerySystemInformation -> HalpAuditQueryResults, info class 26
    SystemBasicPerformanceInformation, // q: SYSTEM_BASIC_PERFORMANCE_INFORMATION // name:wow64:whNtQuerySystemInformation_SystemBasicPerformanceInformation
    SystemQueryPerformanceCounterInformation, // q: SYSTEM_QUERY_PERFORMANCE_COUNTER_INFORMATION // since WIN7 SP1
    SystemSessionBigPoolInformation, // since WIN8
    SystemBootGraphicsInformation,
    SystemScrubPhysicalMemoryInformation,
    SystemBadPageInformation,
    SystemProcessorProfileControlArea,
    SystemCombinePhysicalMemoryInformation, // 130
    SystemEntropyInterruptTimingCallback,
    SystemConsoleInformation,
    SystemPlatformBinaryInformation,
    SystemThrottleNotificationInformation,
    SystemHypervisorProcessorCountInformation,
    SystemDeviceDataInformation,
    SystemDeviceDataEnumerationInformation,
    SystemMemoryTopologyInformation,
    SystemMemoryChannelInformation,
    SystemBootLogoInformation, // 140
    SystemProcessorPerformanceInformationEx, // q: SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION_EX // since WINBLUE
    SystemSpare0,
    SystemSecureBootPolicyInformation,
    SystemPageFileInformationEx, // q: SYSTEM_PAGEFILE_INFORMATION_EX
    SystemSecureBootInformation,
    SystemEntropyInterruptTimingRawInformation,
    SystemPortableWorkspaceEfiLauncherInformation,
    SystemFullProcessInformation, // q: SYSTEM_PROCESS_INFORMATION with SYSTEM_PROCESS_INFORMATION_EXTENSION (requires admin)
    SystemKernelDebuggerInformationEx, // q: SYSTEM_KERNEL_DEBUGGER_INFORMATION_EX
    SystemBootMetadataInformation, // 150
    SystemSoftRebootInformation,
    SystemElamCertificateInformation,
    SystemOfflineDumpConfigInformation,
    SystemProcessorFeaturesInformation, // q: SYSTEM_PROCESSOR_FEATURES_INFORMATION
    SystemRegistryReconciliationInformation,
    SystemEdidInformation,
    SystemManufacturingInformation, // q: SYSTEM_MANUFACTURING_INFORMATION // since THRESHOLD
    SystemEnergyEstimationConfigInformation, // q: SYSTEM_ENERGY_ESTIMATION_CONFIG_INFORMATION
    SystemHypervisorDetailInformation, // q: SYSTEM_HYPERVISOR_DETAIL_INFORMATION
    SystemProcessorCycleStatsInformation, // q: SYSTEM_PROCESSOR_CYCLE_STATS_INFORMATION // 160
    SystemVmGenerationCountInformation,
    SystemTrustedPlatformModuleInformation, // q: SYSTEM_TPM_INFORMATION
    SystemKernelDebuggerFlags,
    SystemCodeIntegrityPolicyInformation,
    SystemIsolatedUserModeInformation,
    SystemHardwareSecurityTestInterfaceResultsInformation,
    SystemSingleModuleInformation, // q: SYSTEM_SINGLE_MODULE_INFORMATION
    SystemAllowedCpuSetsInformation,
    SystemDmaProtectionInformation, // q: SYSTEM_DMA_PROTECTION_INFORMATION
    SystemInterruptCpuSetsInformation,
    SystemSecureBootPolicyFullInformation,
    SystemCodeIntegrityPolicyFullInformation,
    SystemAffinitizedInterruptProcessorInformation,
    SystemRootSiloInformation, // q: SYSTEM_ROOT_SILO_INFORMATION
    SystemCpuSetInformation, // q: SYSTEM_CPU_SET_INFORMATION // since THRESHOLD2
    SystemCpuSetTagInformation, // q: SYSTEM_CPU_SET_TAG_INFORMATION
    SystemWin32WerStartCallout,
    SystemSecureKernelProfileInformation,
    MaxSystemInfoClass
  );

  TSystemInformationClass = SYSTEM_INFORMATION_CLASS;
  TNativeQuerySystemInformation = function(SystemInformationClass : TSystemInformationClass;
                                           SystemInformation : Pointer;
                                           SystemInformationLength : ULong;
                                           ReturnLength : PULong) : NTSTATUS; stdcall;
  TGetFirmwareEnvironmentVariable = function(lpName : PChar;
                                             lpGuid : PChar;
                                             pBuffer : Pointer;
                                             nSize : LongWord) : LongWord; stdcall;

  TServiceConfig = record
    dwServiceType : DWord;
    dwStartType : DWord;
    dwErrorControl : DWord;
    BinaryPathName : String;
    LoadOrderGroup : String;
    dwTagId : DWord;
    Dependencies : String;
    ServiceStartName : String;
    DisplayName : String;
  end;

const
  //Enforcement of kernel mode Code Integrity is enabled.
  CODEINTEGRITY_OPTION_ENABLED = $01;
  //Test signed content is allowed by Code Integrity.
  CODEINTEGRITY_OPTION_TESTSIGN	= $02;
  //Enforcement of user mode Code Integrity is enabled.
  CODEINTEGRITY_OPTION_UMCI_ENABLED	= $04;
  //Enforcement of user mode Code Integrity is enabled in audit mode.
  //Executables will be allowed to run/load; however, audit events will be recorded.
  CODEINTEGRITY_OPTION_UMCI_AUDITMODE_ENABLED	= $08;
  //User mode binaries being run from certain paths are allowed to run even
  //if they fail code integrity checks.
  CODEINTEGRITY_OPTION_UMCI_EXCLUSIONPATHS_ENABLED = $10;
  //The build of Code Integrity is from a test build.
  CODEINTEGRITY_OPTION_TEST_BUILD	= $20;
  //The build of Code Integrity is from a pre-production build.
  CODEINTEGRITY_OPTION_PREPRODUCTION_BUILD = $40;
  //The kernel debugger is attached and Code Integrity may allow unsigned code to load.
  CODEINTEGRITY_OPTION_DEBUGMODE_ENABLED = $80;
  //The build of Code Integrity is from a flight build.
  CODEINTEGRITY_OPTION_FLIGHT_BUILD	= $100;
  //Flight signed content is allowed by Code Integrity. Flight signed content
  //is content signed by the Microsoft Development Root Certificate Authority 2014.
  CODEINTEGRITY_OPTION_FLIGHTING_ENABLED = $200;
  //Hypervisor enforced Code Integrity is enabled for kernel mode components.
  CODEINTEGRITY_OPTION_HVCI_KMCI_ENABLED = $400;
  //Hypervisor enforced Code Integrity is enabled in audit mode.
  //Audit events will be recorded for kernel mode components that
  //are not compatible with HVCI. This bit can be set whether
  //CODEINTEGRITY_OPTION_HVCI_KMCI_ENABLED is set or not.
  CODEINTEGRITY_OPTION_HVCI_KMCI_AUDITMODE_ENABLED = $800;
  //Hypervisor enforced Code Integrity is enabled for
  //kernel mode components, but in strict mode.
  CODEINTEGRITY_OPTION_HVCI_KMCI_STRICTMODE_ENABLED	= $1000;
  //Hypervisor enforced Code Integrity is enabled with enforcement
  //of Isolated User Mode component signing.
  CODEINTEGRITY_OPTION_HVCI_IUM_ENABLED	= $2000;

implementation

end.
