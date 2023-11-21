#include "PCANALYS.h"
#include <ntddk.h>
#include <intrin.h>

#define DRIVER_NAME "PCANALYS Kernel-Mode Driver"

// Definitions

void PCANALYSUnload(PDRIVER_OBJECT DriverObject);
DRIVER_DISPATCH PCANALYSCreateClose, PCANALYSDeviceControl;

// DriverEntry

extern "C" NTSTATUS
DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath) {
	UNREFERENCED_PARAMETER(RegistryPath);

	DriverObject->DriverUnload = PCANALYSUnload;
	DriverObject->MajorFunction[IRP_MJ_CREATE] = DriverObject->MajorFunction[IRP_MJ_CLOSE] = PCANALYSCreateClose;
	DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = PCANALYSDeviceControl;

	UNICODE_STRING DeviceName = RTL_CONSTANT_STRING(L"\\Device\\PCANALYS");
	UNICODE_STRING SymbolicLink = RTL_CONSTANT_STRING(L"\\??\\PCANALYS");
	PDEVICE_OBJECT DeviceObject = nullptr;
	auto ReturnStatus = STATUS_SUCCESS;
	auto SymbolicLinkCreated = false;

	do {
		ReturnStatus = IoCreateDevice(DriverObject, 0, &DeviceName, FILE_DEVICE_UNKNOWN, 0, FALSE, &DeviceObject);
		if (!NT_SUCCESS(ReturnStatus)) {
			KdPrint((DRIVER_NAME ": failed to create device (0x%08X)\n", ReturnStatus));
			break;
		}
		DeviceObject->Flags |= DO_BUFFERED_IO;

		ReturnStatus = IoCreateSymbolicLink(&SymbolicLink, &DeviceName);
		if (!NT_SUCCESS(ReturnStatus)) {
			KdPrint((DRIVER_NAME ": failed to create symbolic link (0x%08X)\n", ReturnStatus));
			break;
		}
		SymbolicLinkCreated = true;

	} while (false);

	if (!NT_SUCCESS(ReturnStatus)) {
		if (SymbolicLinkCreated)
			IoDeleteSymbolicLink(&SymbolicLink);
		if (DeviceObject)
			IoDeleteDevice(DeviceObject);
	}

	return ReturnStatus;
}

// implementation

NTSTATUS FillOutIrp(PIRP Irp, NTSTATUS status = STATUS_SUCCESS, ULONG_PTR info = 0) {
	Irp->IoStatus.Status = status;
	Irp->IoStatus.Information = info;
	IoCompleteRequest(Irp, IO_NO_INCREMENT);
	return status;
}

NTSTATUS PCANALYSCreateClose(PDEVICE_OBJECT, PIRP Irp) {
	return FillOutIrp(Irp);
}

void PCANALYSUnload(PDRIVER_OBJECT DriverObject) {
	UNICODE_STRING SymbolicLink = RTL_CONSTANT_STRING(L"\\??\\PCANALYS");
	IoDeleteSymbolicLink(&SymbolicLink);
	IoDeleteDevice(DriverObject->DeviceObject);
}

NTSTATUS PCANALYSDeviceControl(PDEVICE_OBJECT, PIRP Irp) {
	auto IrpServiceProvider = IoGetCurrentIrpStackLocation(Irp);
	auto& DeviceIOControl = IrpServiceProvider->Parameters.DeviceIoControl;
	auto ReturnStatus = STATUS_INVALID_DEVICE_REQUEST;
	ULONG_PTR Length = 0;

	//PULONG pIOBufferL;
	//unsigned long p_numberL;

	switch (DeviceIOControl.IoControlCode) {
	case IOCTL_PCANALYS_TransferTest:
	{
      if (DeviceIOControl.OutputBufferLength < sizeof(TransferTestOutputStruct)) {
	    ReturnStatus = STATUS_BUFFER_TOO_SMALL;
	    break;
	  }

	  auto TransferTestBuffer = (TransferTestOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
	  if (TransferTestBuffer == nullptr) {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	    break;
	  }
		
	  TransferTestBuffer->TransferTest = 0x12345678;
	  ReturnStatus = STATUS_SUCCESS;
	  Length = sizeof(TransferTestBuffer);
	  break;
	}

	case IOCTL_PCANALYS_Version:
	{
	  if (DeviceIOControl.OutputBufferLength < sizeof(VersionOutputStruct)) {
		ReturnStatus = STATUS_BUFFER_TOO_SMALL;
		break;
	  }
	  auto VersionBuffer = (VersionOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
	  if (VersionBuffer == nullptr) {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
		break;
	  }

	  //Definition of the driver version and date:
	  //00 - Dummy, 01 - HiVer, 01 - LoVer, 00 - ErrVer
	  VersionBuffer->Version = 0x00010100;
	  //18 - Day, 05 - Month, 2022 - Year
	  VersionBuffer->Date = 0x18052022;
	  ReturnStatus = STATUS_SUCCESS;
	  Length = sizeof(VersionBuffer);
	  break;
	}

	case IOCTL_PCANALYS_ReadMSR:
	{
	  if ((DeviceIOControl.InputBufferLength  == 4) &&
		  (DeviceIOControl.OutputBufferLength == 8))
	  {
		//Assignment of the used In/Out buffer
		auto ReadMSRInputBuffer = (ReadMSRInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMSRInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadMSROutputBuffer = (ReadMSROutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMSROutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}
			
		__try
		{
		  ULONG ulECX = ReadMSRInputBuffer->ECXReg;
		  ULONG ulEAX, ulEDX = 0;
		  ULONG64 MSR64Bit;
		  MSR64Bit = __readmsr(ulECX);

		  ulEAX = (ULONG)MSR64Bit;         //First 4 Bytes
		  ulEDX = (ULONG)(MSR64Bit >> 32); //Last 4 Bytes

		  ReadMSROutputBuffer->EDXReg = ulEDX;
		  ReadMSROutputBuffer->EAXReg = ulEAX;
				
		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ReadMSROutputBuffer);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		  {
			ReturnStatus = STATUS_ILLEGAL_INSTRUCTION;
		  }
	  }
	  else
	  {
		ReturnStatus = STATUS_BUFFER_TOO_SMALL;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_WriteMSR:
	{
	  if (DeviceIOControl.InputBufferLength == 12)
	  {
		//Assignment of the used In/Out buffer
		auto WriteMSRInputBuffer = (WriteMSRInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WriteMSRInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		//check if MSR is on the blacklist
		//SYSENTER instruction (mostly x86 at this point)
		//IA32_SYSENTER_CS (value of CS, when SYSENTER is executed)
		if ((WriteMSRInputBuffer->ECXReg == 0x00000174) | 
			//IA32_SYSENTER_ESP (value of ESP, when SYSENTER is executed)
			(WriteMSRInputBuffer->ECXReg == 0x00000175) | 
			//IA32_SYSENTER_EIP (value of EIP, when SYSENTER is executed)
			(WriteMSRInputBuffer->ECXReg == 0x00000176) | 
			//SYSCALL instruction 
			//IA32_STAR (Ring 0 and Ring 3 segment bases as well as SYSCALL EIP for x86)
			(WriteMSRInputBuffer->ECXReg == 0xC0000081) | 
			//IA32_LSTAR (SYSCALL entry pointer (RIP) in x64)
			(WriteMSRInputBuffer->ECXReg == 0xC0000082) | 
			//IA32_CSTAR (SYSCALL entry pointer in)
			(WriteMSRInputBuffer->ECXReg == 0xC0000083) | 
			//IA32_SYSCALL_MASK (EFLAGS (RFLAGS) mask for SYSCALL)
			(WriteMSRInputBuffer->ECXReg == 0xC0000084))  
		{
		  ReturnStatus = STATUS_ILLEGAL_INSTRUCTION;
		}
		else
		{
		  __try
		  {
			ULONG ulECX = WriteMSRInputBuffer->ECXReg;   //ECX: MSR number
			ULONG64 ulEDX = WriteMSRInputBuffer->EDXReg; //EDX: upper register content
			ULONG64 ulEAX = WriteMSRInputBuffer->EAXReg; //EAX: lower register content
			ULONG64 MSR64Bit = (ulEDX << 32) + ulEAX;    //composite 64 bit value

			__writemsr(ulECX, MSR64Bit);
			ReturnStatus = STATUS_SUCCESS;
          }
		  __except (EXCEPTION_EXECUTE_HANDLER)
		  {
		    ReturnStatus = STATUS_UNSUCCESSFUL;
		  }
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_ReadPCI:
	{
	  if ((DeviceIOControl.InputBufferLength == 4) &&
	      (DeviceIOControl.OutputBufferLength == 4))
	  {
		//Assignment of the used In/Out buffer
		auto ReadPCIInputBuffer = (ReadPCIInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPCIInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadPCIOutputBuffer = (ReadPCIOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPCIOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		//Insert read address into CONFIG_ADDRESS register 0x0cf8
		WRITE_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cf8), ReadPCIInputBuffer->PortNumber);

		//Read the CONFIG_DATA register 0x0cfc to read out the content
		unsigned long PCIPortResult = READ_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cfc));

		ReadPCIOutputBuffer->DataBuffer = PCIPortResult;

		//Return status and length
		ReturnStatus = STATUS_SUCCESS;
		Length = sizeof(ReadPCIOutputBuffer);
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_WritePCI:
	{
	  if ((DeviceIOControl.InputBufferLength == 8) &&
		  (DeviceIOControl.OutputBufferLength == 4))
	  {
		//Assignment of the used In/Out buffer
		auto WritePCIInputBuffer = (WritePCIInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WritePCIInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto WritePCIOutputBuffer = (WritePCIOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WritePCIOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}		

		if (WritePCIInputBuffer->PortNumber & 0x80000000)
		{
		  //Insert write address into CONFIG_ADDRESS register 0x0cf8
		  WRITE_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cf8), WritePCIInputBuffer->PortNumber);

		  //Write the CONFIG_DATA register 0x0cfc to transfer the contents
		  WRITE_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cfc), WritePCIInputBuffer->DataBuffer);

		  //Insert read address into CONFIG_ADDRESS register 0x0cf8
		  WRITE_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cf8), WritePCIInputBuffer->PortNumber);

		  //Read the CONFIG_DATA register 0x0cfc to read out the content
		  unsigned long PCIPortResult = READ_PORT_ULONG((PULONG)(ULONG_PTR)(0x0cfc));

		  //Verification of the written value with the read one value
		  //takes place in the user mode program, therefore return of the read value
		  WritePCIOutputBuffer->DataBuffer = PCIPortResult;

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(WritePCIOutputBuffer);
		}
		else
		{
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_ReadMem8Bit:
	{
      if ((DeviceIOControl.InputBufferLength  == 4) &&
		  (DeviceIOControl.OutputBufferLength == 1))
      {
	    //Assignment of the used In/Out buffer
		auto ReadMem8BitInputBuffer = (ReadMemXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem8BitInputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadMem8BitOutputBuffer = (ReadMem8BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem8BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(ReadMem8BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 1, MmNonCached);
		  *(PUCHAR)ReadMem8BitOutputBuffer = *(UCHAR*)LinearAddress;
		  MmUnmapIoSpace(LinearAddress, 1);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_ReadMem16Bit:
	{
	  if ((DeviceIOControl.InputBufferLength  == 4) &&
		  (DeviceIOControl.OutputBufferLength == 2))
	  {
	    //Assignment of the used In/Out buffer
		auto ReadMem16BitInputBuffer = (ReadMemXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem16BitInputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadMem16BitOutputBuffer = (ReadMem16BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem16BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(ReadMem16BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 2, MmNonCached);
		  *(PUSHORT)ReadMem16BitOutputBuffer = *(USHORT*)LinearAddress;
		  MmUnmapIoSpace(LinearAddress, 2);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_ReadMem32Bit:
	{
	  if ((DeviceIOControl.InputBufferLength  == 4) &&
		  (DeviceIOControl.OutputBufferLength == 4))
      {
	    //Assignment of the used In/Out buffer
		auto ReadMem32BitInputBuffer = (ReadMemXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem32BitInputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadMem32BitOutputBuffer = (ReadMem32BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadMem32BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(ReadMem32BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 4, MmNonCached);
		  *(PULONG)ReadMem32BitOutputBuffer = *(ULONG*)LinearAddress;
		  MmUnmapIoSpace(LinearAddress, 4);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_WriteMem8Bit:
	{
	  if (DeviceIOControl.InputBufferLength  == 5)
	  {
	    //Assignment of the used In/Out buffer
	    auto WriteMem8BitInputBuffer = (WriteMem8BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WriteMem8BitInputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(WriteMem8BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 1, MmNonCached);	
		  WRITE_REGISTER_BUFFER_UCHAR((PUCHAR)LinearAddress, (UCHAR*)&WriteMem8BitInputBuffer->Data, 1);
		  MmUnmapIoSpace(LinearAddress, 1);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
	    }
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
      break;
	}

	case IOCTL_PCANALYS_WriteMem16Bit:
	{
      if (DeviceIOControl.InputBufferLength == 6)
	  {
		//Assignment of the used In/Out buffer
		auto WriteMem16BitInputBuffer = (WriteMem16BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WriteMem16BitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(WriteMem16BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 2, MmNonCached);
		  WRITE_REGISTER_BUFFER_USHORT((PUSHORT)LinearAddress, (USHORT*)&WriteMem16BitInputBuffer->Data, 2);
		  MmUnmapIoSpace(LinearAddress, 2);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}

	case IOCTL_PCANALYS_WriteMem32Bit:
	{
      if (DeviceIOControl.InputBufferLength == 8)
	  {
	    //Assignment of the used In/Out buffer
		auto WriteMem32BitInputBuffer = (WriteMem32BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WriteMem32BitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  PHYSICAL_ADDRESS PAddress;
		  PAddress.HighPart = 0;
		  PAddress.LowPart = (ULONG)(WriteMem32BitInputBuffer->Address);
		  PVOID LinearAddress;
		  LinearAddress = MmMapIoSpace(PAddress, 4, MmNonCached);
		  WRITE_REGISTER_BUFFER_ULONG((PULONG)LinearAddress, (ULONG*)&WriteMem32BitInputBuffer->Data, 4);
		  MmUnmapIoSpace(LinearAddress, 1);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}

	case IOCTL_PCANALYS_ReadPort8Bit:
	{
	  if ((DeviceIOControl.InputBufferLength  == 4) &&
	      (DeviceIOControl.OutputBufferLength == 1))
	  {
		//Assignment of the used In/Out buffer
		auto ReadPortXBitInputBuffer = (ReadPortXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPortXBitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}
		
		auto ReadPort8BitOutputBuffer = (ReadPort8BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPort8BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}
		
		unsigned char OutputBuf = 0;
		
		__try
		{ 	
		  OutputBuf = READ_PORT_UCHAR((PUCHAR)(ULONG_PTR)(ReadPortXBitInputBuffer->Address));
		  *(PUCHAR)ReadPort8BitOutputBuffer = OutputBuf;

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_ReadPort16Bit:
	{
	  if ((DeviceIOControl.InputBufferLength  == 4) &&
	      (DeviceIOControl.OutputBufferLength == 2))
	  {
	    //Assignment of the used In/Out buffer
	    auto ReadPortXBitInputBuffer = (ReadPortXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
	    if (ReadPortXBitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
	      break;
		}

		auto ReadPort16BitOutputBuffer = (ReadPort16BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPort16BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		unsigned short OutputBuf = 0;

		__try
		{
		  OutputBuf = READ_PORT_USHORT((PUSHORT)(ULONG_PTR)(ReadPortXBitInputBuffer->Address));
		  *(PUSHORT)ReadPort16BitOutputBuffer = OutputBuf;
				
		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
	    ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}

	case IOCTL_PCANALYS_ReadPort32Bit:
	{
      if ((DeviceIOControl.InputBufferLength  == 4) &&
			(DeviceIOControl.OutputBufferLength == 4))
	  {
	    //Assignment of the used In/Out buffer
		auto ReadPortXBitInputBuffer = (ReadPortXBitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPortXBitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		auto ReadPort32BitOutputBuffer = (ReadPort32BitOutputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (ReadPort32BitOutputBuffer == nullptr) {
		  ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		unsigned long OutputBuf = 0;

		__try
		{
		  OutputBuf = READ_PORT_ULONG((PULONG)(ULONG_PTR)(ReadPortXBitInputBuffer->Address));
		  *(PULONG)ReadPort32BitOutputBuffer = OutputBuf;
		  
		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		  Length = sizeof(ULONG);
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}

	case IOCTL_PCANALYS_WritePort8Bit:
	{
	  if (DeviceIOControl.InputBufferLength == 5)
	  {
		//Assignment of the used In/Out buffer
		auto WritePort8BitInputBuffer = (WritePort8BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WritePort8BitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  WRITE_PORT_UCHAR((PUCHAR)(ULONG_PTR)(WritePort8BitInputBuffer->Address), WritePort8BitInputBuffer->Data);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}

	case IOCTL_PCANALYS_WritePort16Bit:
	{
      if (DeviceIOControl.InputBufferLength == 6)
	  {
		//Assignment of the used In/Out buffer
		auto WritePort16BitInputBuffer = (WritePort16BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WritePort16BitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  WRITE_PORT_USHORT((PUSHORT)(ULONG_PTR)(WritePort16BitInputBuffer->Address), WritePort16BitInputBuffer->Data);
				
		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
	
	case IOCTL_PCANALYS_WritePort32Bit:
	{
      if (DeviceIOControl.InputBufferLength == 8)
	  {
		//Assignment of the used In/Out buffer
		auto WritePort32BitInputBuffer = (WritePort32BitInputStruct*)Irp->AssociatedIrp.SystemBuffer;
		if (WritePort32BitInputBuffer == nullptr) {
	      ReturnStatus = STATUS_INVALID_PARAMETER;
		  break;
		}

		__try
		{
		  WRITE_PORT_ULONG((PULONG)(ULONG_PTR)(WritePort32BitInputBuffer->Address), WritePort32BitInputBuffer->Data);

		  //Return status and length
		  ReturnStatus = STATUS_SUCCESS;
		}
		__except (EXCEPTION_EXECUTE_HANDLER)
		{
		  ReturnStatus = STATUS_UNSUCCESSFUL;
		}
	  }
	  else
	  {
		ReturnStatus = STATUS_INVALID_PARAMETER;
	  }
	  break;
	}
  }
	
  return FillOutIrp(Irp, ReturnStatus, Length);
}
