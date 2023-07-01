;********************************************
; �{�ǧ@�� : �f��
; �}�o��� : 2023�~6��7��
; �\��y�z : ���O�����ε{��
; �`�N�ƶ� : 
; ��s���v : 
;********************************************
.586
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include comdlg32.inc
   
includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


.data
   ClassName		db "MainWinClass",0			; ���f���W
   AppName 			db "Notepad �f��",0 		; ���ε{�Ǽ��D�W
   AboutApp 		db "�o�O�f���ηJ�s�y���Ҷ}�oWin32���O�ƥ�", 0
   
   editClass 		db "edit", 0
   
   ; �եΤ��@��ܮةҥ��n�T��
   szFitler			db "���(*.txt)", 0, "*.txt", 0, "�Ҧ����(*.*)", 0, "*.*", 0, 0
   szDefExt 		db "txt", 0
   
   ; "���}" �M "�O�s" ��󪺼��D
   szOpenTitle		db "Open", 0
   szSaveTitle		db "Save", 0
   
.data?
   hInstance 		HINSTANCE 	?			; ���ε{�Ǫ��y�`
   CommandLine 		LPSTR 		?			; �{�Ǫ��R�O��ѼƦr�Ŧ���w
   hEdit			HWND		?			; �奻�s��ت��y�`
   strFile			db MAX_PATH	dup (?)		; �O�s���@��ܮ���������W
   
   strFileBuf		db 81920	dup (?)

.code
	; �ϼ�
	App_Icon = 1
	;Res\MainMenu.mnu
	IDR_MENU					equ 10000
	IDM_File					equ 10001
	IDM_Open_File				equ 10002
	IDM_Save_File				equ 10003
	IDM_Line					equ 10004
	IDM_File_Exit				equ 10005
	IDM_Edit					equ 10006
	IDM_Edit_Undo				equ 10007
	IDM_Edit_Redo				equ 10008
	IDM_Line2					equ 10009
	IDM_Edit_Cut				equ 10010
	IDM_Edit_Copy				equ 10011
	IDM_Edit_Paste				equ 10012
	IDM_Help					equ 10013
	IDM_Help_About				equ 10014


;**********************************************************************************************
; �{�ǤJ�f�I
start:
	; ���{�ǥͦ��@�ӹ�ҥy�`
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	; ���{������@�өR�O��Ѽ�
	invoke GetCommandLine
	mov    CommandLine,eax
	
	; �ե�Windows���D���
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax


WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
;**********************************************************************************************
	; ��Rwindows�����f���c��
	mov   wc.cbSize,SIZEOF WNDCLASSEX				; ���ܵ��f���c�骺�`�j�p
	mov   wc.style, CS_HREDRAW or CS_VREDRAW		; ���f����
	mov   wc.lpfnWndProc, OFFSET WndProc			; �ǻ������B�z��ƪ����w
	mov   wc.cbClsExtra,NULL						; ���f�������[�ƾ�
	mov   wc.cbWndExtra,NULL						; ���f�����[�ƾ�
	
	push  hInstance									; �ǻ��{�Ǫ���ҥy�`�����f��
	pop   wc.hInstance
	
	mov   wc.hbrBackground,COLOR_BTNFACE+1			; �Ыص��f�ɪ��q�{�I���C��

	mov   wc.lpszMenuName,IDR_MENU					; �������f�إߤ@�ӥD���
	mov   wc.lpszClassName,OFFSET ClassName			; ���f�����W��
	
	invoke LoadIcon,NULL,IDI_APPLICATION			; �������f�إߤ@�ӹϼ�
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW				; ���w���f�W�����Ы��w����
	mov   wc.hCursor,eax
;**********************************************************************************************
	
	; �VWindows���U�@�ӵ��f
	invoke RegisterClassEx, addr wc
	
	; �Ыؤ@�ӵ��f �M��ⵡ�f�y�`��ȵ�hwnd�ܶq
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,450,650,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax
	
	; ��ܤ@�ӵ��f
	invoke ShowWindow, hwnd,SW_SHOWNORMAL
	; ��s�@�ӵ��f
	invoke UpdateWindow, hwnd
	
	; �i�J�F�B�z�������`��
	.WHILE TRUE
		; ����@������
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		
		; �ഫ���� ���o����
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	
	mov     eax,msg.wParam
	ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	LOCAL winRect: 		RECT
	LOCAL editWidth: 	DWORD
	LOCAL editHeight: 	DWORD
	
	LOCAL ofn:			OPENFILENAME
	LOCAL hFile:		HANDLE
	LOCAL bytesRead:	DWORD
	LOCAL bytesWrite:	DWORD
	LOCAL textLen:		DWORD
	
	.IF uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL
		
	.ELSEIF uMsg == WM_CREATE
		invoke LoadIcon, hInstance,App_Icon		; �������f�إߤ@�ӹϼ�
		invoke SendMessage, hWnd, WM_SETICON, ICON_BIG, eax
		
		; �Ыؤ@�Ӥ奻�s�����
		invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset editClass, NULL, WS_MAXIMIZE OR \
							ES_AUTOHSCROLL OR ES_AUTOVSCROLL OR ES_MULTILINE OR \
							WS_CHILDWINDOW OR WS_VISIBLE OR WS_VSCROLL OR WS_HSCROLL,\
		 					0, 0, 1000, 480, hWnd, NULL, hInstance, NULL
		mov hEdit, eax
		
		; invoke ColorCorrectPalette,
		
	.ELSEIF	uMsg == WM_SIZE
		; ������e���������� x, y, top, bottom
		; invoke GetWindowRect, hWnd, addr winRect
		invoke GetClientRect, hWnd, addr winRect

		; �p��X�������s�e�שM����
		mov eax, winRect.right
		sub eax, winRect.left
		; sub eax, 15
		mov editWidth, eax
		
		mov eax, winRect.bottom
		sub eax, winRect.top
		; sub eax, 40
		mov editHeight, eax
		
		; ���ܤ奻�s��ت��e�שM����
		invoke MoveWindow, hEdit, 0, 0, editWidth, editHeight, TRUE
		
	.ELSEIF	uMsg == WM_COMMAND
		mov	eax, wParam

		.if ax == IDM_Open_File
			; ��� -> ���}
			; ��l�Ƥ��@��ܮص��c��
			invoke RtlZeroMemory, addr ofn, sizeof ofn
			invoke RtlZeroMemory, offset strFile, sizeof strFile	
			mov 	ofn.lStructSize, sizeof ofn
			push 	hWnd
			pop 	ofn.hwndOwner
			mov 	ofn.lpstrFile, 			offset strFile
			mov 	ofn.nMaxFile, 			MAX_PATH
			mov 	ofn.lpstrFilter, 		offset szFitler
			mov		ofn.lpstrTitle,			offset szOpenTitle
			mov 	ofn.nFilterIndex, 		1
			mov 	ofn.lpstrFileTitle, 	NULL
			mov 	ofn.nMaxFileTitle, 		0
			mov 	ofn.lpstrInitialDir,	NULL
			mov		ofn.Flags, OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
			
			; �եΥ��}��󪺤��@��ܮ� ��������|
			invoke GetOpenFileName, addr ofn
			.if eax == TRUE
				; invoke MessageBox, hWnd, offset strFile, addr AppName, MB_OK or MB_ICONINFORMATION
				; ��o�Ӥ��i��B�z
				invoke CreateFile, offset strFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				.if eax != INVALID_HANDLE_VALUE
					;invoke RtlZeroMemory, addr ofn, sizeof ofn
					invoke RtlZeroMemory, offset strFile, sizeof strFile
					mov hFile, eax
					; Ū����󤺮e��w�İ�strFileBuf��
					invoke ReadFile, hFile, offset strFileBuf, sizeof strFileBuf, addr bytesRead, NULL
					; �M�ŭ쥻����󤺮e �M��NstrFileBuf�����e��ܨ�奻�ؤ�
					invoke SendMessage,	hEdit, WM_CLEAR, 0, 0
					invoke SetWindowText, hEdit, offset strFileBuf
					; �������e�����y�`
					invoke CloseHandle,	hFile
				.endif
			.endif
			
		.elseif ax == IDM_Save_File
			; ��� -> �O�s
			; ��l�Ƥ��@��ܮص��c��
			invoke RtlZeroMemory, addr ofn, sizeof ofn
			invoke RtlZeroMemory, offset strFile, sizeof strFile	
			mov 	ofn.lStructSize, sizeof ofn
			push 	hWnd
			pop 	ofn.hwndOwner
			mov 	ofn.lpstrFile,			offset strFile
			mov 	ofn.nMaxFile, 			MAX_PATH
			mov 	ofn.lpstrFilter, 		offset szFitler
			mov		ofn.lpstrTitle,			offset szSaveTitle
			mov 	ofn.nFilterIndex, 		1
			mov 	ofn.lpstrFileTitle, 	NULL
			mov 	ofn.nMaxFileTitle, 		0
			mov 	ofn.lpstrInitialDir, 	NULL
			mov		ofn.lpstrDefExt, 	offset	szDefExt
			mov		ofn.Flags, OFN_OVERWRITEPROMPT or OFN_EXPLORER
			
			; �եΫO�s��󪺤��@��ܮ� ��������|
			invoke GetSaveFileName, addr ofn
			.if eax == TRUE
				; invoke MessageBox, hWnd, offset strFile, addr AppName, MB_OK or MB_ICONINFORMATION
				; ���}���
				invoke CreateFile, offset strFile, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
				.if eax != INVALID_HANDLE_VALUE
					; ����奻�ت����e
					mov hFile, eax
					invoke RtlZeroMemory, offset strFileBuf, sizeof	strFileBuf
					invoke GetWindowTextLength, hEdit
					mov textLen, eax
					invoke GetWindowText, hEdit, offset strFileBuf, sizeof strFileBuf
					
					; �N�奻���e�g�J���
					invoke WriteFile, hFile, offset strFileBuf, textLen,addr bytesWrite, NULL
					invoke CloseHandle, hFile
				.endif
			.endif
			
			; ��o�Ӥ��i��B�z
		
		.elseif ax == IDM_File_Exit
			; ��� -> �h�X���ε{��
			invoke DestroyWindow, hWnd
			invoke PostQuitMessage,NULL
			
		.elseif ax == IDM_Edit_Undo
			; �s�� -> �M�P 
			invoke SendMessage, hEdit, EM_UNDO, 0, 0
			
		.elseif ax == IDM_Edit_Redo
			; �s�� -> ����
			invoke SendMessage, hEdit, EM_REDO, 0, 0
			
		.elseif ax == IDM_Edit_Cut
			; �s�� -> �Ť�
			invoke SendMessage, hEdit, WM_CUT, 0, 0
			
		.elseif ax == IDM_Edit_Copy
			; �s�� -> �ƻs
			invoke SendMessage, hEdit, WM_COPY, 0, 0
			
		.elseif ax == IDM_Edit_Paste
			; �s�� -> �߶K
			invoke SendMessage, hEdit, WM_PASTE, 0, 0
		
		.elseif ax == IDM_Help_About
			; ��� -> ����
			invoke MessageBox, hWnd, addr AboutApp, addr AppName, MB_OK or MB_ICONINFORMATION
			
		.endif
			
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
	
	xor eax,eax
	ret
WndProc endp


end start