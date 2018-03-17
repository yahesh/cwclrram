program cwclrram;

{$APPTYPE CONSOLE}

uses
  Windows, TLHelp32, SysUtils;

const
  PSAPI = 'psapi.dll';

type
  SIZE_T = LongWord;

  _PROCESS_MEMORY_COUNTERS = record
    cb                         : DWORD;
    PageFaultCount             : DWORD;
    PeakWorkingSetSize         : SIZE_T;
    WorkingSetSize             : SIZE_T;
    QuotaPeakPagedPoolUsage    : SIZE_T;
    QuotaPagedPoolUsage        : SIZE_T;
    QuotaPeakNonPagedPoolUsage : SIZE_T;
    QuotaNonPagedPoolUsage     : SIZE_T;
    PagefileUsage              : SIZE_T;
    PeakPagefileUsage          : SIZE_T;
  end;
  PROCESS_MEMORY_COUNTERS  = _PROCESS_MEMORY_COUNTERS;
  PPROCESS_MEMORY_COUNTERS = ^PROCESS_MEMORY_COUNTERS;
  TProcessMemoryCounters   = PROCESS_MEMORY_COUNTERS;

function GetProcessMemoryInfo(Process : THandle; ppsmemCounters : PPROCESS_MEMORY_COUNTERS; cb : DWORD) : BOOL; stdcall; external PSAPI;

var
  VProcess               : THandle;
  VProcessEntry          : TProcessEntry32;
  VProcessMemoryCounters : TProcessMemoryCounters;
  VSnapshot              : THandle;

const
  CErrorText = 'ERROR - PROCEEDING';

begin
  WriteLn('cwClearRAM 0.1b');
  WriteLn('(hello@yahe.sh)');
  WriteLn('');
  WriteLn('ProcessList:');

  VProcessEntry.dwSize      := SizeOf(VProcessEntry);
  VProcessMemoryCounters.cb := SizeOf(VProcessMemoryCounters);

  VSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    if Process32First(VSnapShot, VProcessEntry) then
    begin
      repeat
        WriteLn(ExtractFileName(VProcessEntry.szExeFile) + ': ' + IntToStr(VProcessEntry.th32ProcessID));

        VProcess := OpenProcess(PROCESS_SET_QUOTA or PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, VProcessEntry.th32ProcessID);
        if (VProcess > 0) and (VProcess <> INVALID_HANDLE_VALUE) then
        begin
          try
            if GetProcessMemoryInfo(VProcess, @VProcessMemoryCounters, SizeOf(VProcessMemoryCounters)) then
              WriteLn('Before: ' + IntToStr(VProcessMemoryCounters.WorkingSetSize div 1024) + ' KB') 
            else 
              WriteLn('Before: ' + CErrorText); 

            if not(SetProcessWorkingSetSize(VProcess, $FFFFFFFF, $FFFFFFFF)) then 
              WriteLn(CErrorText); 

            if GetProcessMemoryInfo(VProcess, @VProcessMemoryCounters, SizeOf(VProcessMemoryCounters)) then
              WriteLn('After : ' + IntToStr(VProcessMemoryCounters.WorkingSetSize div 1024) + ' KB') 
            else 
              WriteLn('After : ' + CErrorText); 
          finally 
            CloseHandle(VProcess); 
          end; 
        end 
        else 
          WriteLn(CErrorText); 

        WriteLn(''); 
      until not(Process32Next(VSnapshot, VProcessEntry));
    end; 
  finally 
    CloseHandle(VSnapshot); 
  end; 
end.
