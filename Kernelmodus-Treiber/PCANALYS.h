#pragma once

#include <ntddk.h>

#define DEVICE_PCANALYS 0x8000

#define IOCTL_PCANALYS_TransferTest CTL_CODE(DEVICE_PCANALYS, 0x800, METHOD_BUFFERED, FILE_READ_DATA)
struct TransferTestOutputStruct {
	unsigned long TransferTest;
};

#define IOCTL_PCANALYS_Version CTL_CODE(DEVICE_PCANALYS, 0x801, METHOD_BUFFERED, FILE_READ_DATA)
struct VersionOutputStruct {
	unsigned long Version, Date;
};

#define IOCTL_PCANALYS_ReadMSR CTL_CODE(DEVICE_PCANALYS, 0x900, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadMSRInputStruct {
	unsigned long ECXReg;
};

struct ReadMSROutputStruct {
	unsigned long EAXReg, EDXReg;
};

#define IOCTL_PCANALYS_WriteMSR CTL_CODE(DEVICE_PCANALYS, 0x901, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WriteMSRInputStruct {
	unsigned long ECXReg /*MSR number*/, EDXReg /*upper register content*/, EAXReg /*lower register content*/;
};

#define IOCTL_PCANALYS_ReadPCI CTL_CODE(DEVICE_PCANALYS, 0x902, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadPCIInputStruct {
	unsigned long PortNumber;
};

struct ReadPCIOutputStruct {
	unsigned long DataBuffer;
};

#define IOCTL_PCANALYS_WritePCI CTL_CODE(DEVICE_PCANALYS, 0x903, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WritePCIInputStruct {
	unsigned long PortNumber, DataBuffer;
};

struct WritePCIOutputStruct {
	unsigned long DataBuffer;
};

#define IOCTL_PCANALYS_ReadMem8Bit CTL_CODE(DEVICE_PCANALYS, 0x904, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadMemXBitInputStruct {
	unsigned long Address;
};

struct ReadMem8BitOutputStruct {
	unsigned char Data;
};

#define IOCTL_PCANALYS_ReadMem16Bit CTL_CODE(DEVICE_PCANALYS, 0x905, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadMem16BitOutputStruct {
	unsigned short Data;
};

#define IOCTL_PCANALYS_ReadMem32Bit CTL_CODE(DEVICE_PCANALYS, 0x906, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadMem32BitOutputStruct {
	unsigned long Data;
};

#define IOCTL_PCANALYS_WriteMem8Bit CTL_CODE(DEVICE_PCANALYS, 0x907, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WriteMem8BitInputStruct {
	unsigned long Address;
	unsigned char Data;
};

#define IOCTL_PCANALYS_WriteMem16Bit CTL_CODE(DEVICE_PCANALYS, 0x908, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WriteMem16BitInputStruct {
	unsigned long Address;
	unsigned short Data;
};

#define IOCTL_PCANALYS_WriteMem32Bit CTL_CODE(DEVICE_PCANALYS, 0x909, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WriteMem32BitInputStruct {
	unsigned long Address, Data;
};

#define IOCTL_PCANALYS_ReadPort8Bit CTL_CODE(DEVICE_PCANALYS, 0x90A, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadPortXBitInputStruct {
	unsigned long Address;
};

struct ReadPort8BitOutputStruct {
	unsigned char Data;
};

#define IOCTL_PCANALYS_ReadPort16Bit CTL_CODE(DEVICE_PCANALYS, 0x90B, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadPort16BitOutputStruct {
	unsigned short Data;
};

#define IOCTL_PCANALYS_ReadPort32Bit CTL_CODE(DEVICE_PCANALYS, 0x90C, METHOD_BUFFERED, FILE_READ_DATA)
struct ReadPort32BitOutputStruct {
	unsigned long Data;
};

#define IOCTL_PCANALYS_WritePort8Bit CTL_CODE(DEVICE_PCANALYS, 0x90D, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WritePort8BitInputStruct {
	unsigned long Address;
	unsigned char Data;
};

#define IOCTL_PCANALYS_WritePort16Bit CTL_CODE(DEVICE_PCANALYS, 0x90E, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WritePort16BitInputStruct {
	unsigned long Address;
	unsigned short Data;
};

#define IOCTL_PCANALYS_WritePort32Bit CTL_CODE(DEVICE_PCANALYS, 0x90F, METHOD_BUFFERED, FILE_READ_DATA | FILE_WRITE_DATA)
struct WritePort32BitInputStruct {
	unsigned long Address, Data;
};