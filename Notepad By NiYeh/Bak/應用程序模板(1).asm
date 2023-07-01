;--------------------------------------------------------------------------------
; �{�ǧ@�� : �f��
; �}�o��� : 2023�~6��5��
; �\��y�z : �ӤH���ε{�ǭ��O
; �`�N�ƶ� : 
; ��s���v : 
;--------------------------------------------------------------------------------
.586
.model flat,stdcall
option casemap:none

   include windows.inc
   include user32.inc
   include kernel32.inc
   
   includelib user32.lib
   includelib kernel32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


.data
   ClassName db "MainWinClass",0		; ���f���W
   AppName  db "����",0 				; ���ε{�Ǽ��D�W

.data?
   hInstance HINSTANCE ?			; ���ε{�Ǫ��y�`
   CommandLine LPSTR ?				; �{�Ǫ��R�O��ѼƦr�Ŧ���w

.code


; ---------------------------------------------------------------------------
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
	;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	; ��Rwindows�����f���c��
	mov   wc.cbSize,SIZEOF WNDCLASSEX				; ��ܵ��f���c�骺�`�j�p
	mov   wc.style, CS_HREDRAW or CS_VREDRAW		; ���f����
	mov   wc.lpfnWndProc, OFFSET WndProc			; �ǻ������B�z��ƪ����w
	mov   wc.cbClsExtra,NULL						; ���f�������[�ƾ�
	mov   wc.cbWndExtra,NULL						; ���f�����[�ƾ�
	
	push  hInstance								; �ǻ��{�Ǫ���ҥy�`�����f��
	pop   wc.hInstance
	
	mov   wc.hbrBackground,COLOR_BTNFACE+1		; �Ыص��f�ɪ��q�{�I���C��
	mov   wc.lpszMenuName,NULL					; �������f�إߤ@�ӥD���
	mov   wc.lpszClassName,OFFSET ClassName			; ���f�����W��
	
	invoke LoadIcon,NULL,IDI_APPLICATION			; �������f�إߤ@�ӹϼ�
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW				; ���w���f�W�����Ы��w����
	mov   wc.hCursor,eax
	;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	; �VWindows���U�@�ӵ��f
	invoke RegisterClassEx, addr wc
	
	; �Ыؤ@�ӵ��f �M��ⵡ�f�y�`��ȵ�hwnd�ܶq
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
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
	
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.ELSEIF uMsg==WM_CREATE
		;
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
	
	xor eax,eax
	ret
WndProc endp


end start
