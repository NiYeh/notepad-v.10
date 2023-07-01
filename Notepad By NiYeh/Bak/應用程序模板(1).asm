;--------------------------------------------------------------------------------
; 程序作者 : 逆葉
; 開發日期 : 2023年6月5日
; 功能描述 : 個人應用程序面板
; 注意事項 : 
; 更新歷史 : 
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
   ClassName db "MainWinClass",0		; 窗口類名
   AppName  db "視窗",0 				; 應用程序標題名

.data?
   hInstance HINSTANCE ?			; 應用程序的句柄
   CommandLine LPSTR ?				; 程序的命令行參數字符串指針

.code


; ---------------------------------------------------------------------------
; 程序入口點
start:
	; 為程序生成一個實例句柄
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	; 為程序獲取一個命令行參數
	invoke GetCommandLine
	mov    CommandLine,eax
	
	; 調用Windows的主函數
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax


WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	; 填充windows的窗口結構體
	mov   wc.cbSize,SIZEOF WNDCLASSEX				; 表示窗口結構體的總大小
	mov   wc.style, CS_HREDRAW or CS_VREDRAW		; 窗口類型
	mov   wc.lpfnWndProc, OFFSET WndProc			; 傳遞消息處理函數的指針
	mov   wc.cbClsExtra,NULL						; 窗口類的附加數據
	mov   wc.cbWndExtra,NULL						; 窗口的附加數據
	
	push  hInstance								; 傳遞程序的實例句柄給窗口類
	pop   wc.hInstance
	
	mov   wc.hbrBackground,COLOR_BTNFACE+1		; 創建窗口時的默認背景顏色
	mov   wc.lpszMenuName,NULL					; 為此窗口建立一個主菜單
	mov   wc.lpszClassName,OFFSET ClassName			; 窗口類的名稱
	
	invoke LoadIcon,NULL,IDI_APPLICATION			; 為此窗口建立一個圖標
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW				; 指定窗口上的鼠標指針類型
	mov   wc.hCursor,eax
	;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	; 向Windows註冊一個窗口
	invoke RegisterClassEx, addr wc
	
	; 創建一個窗口 然後把窗口句柄賦值給hwnd變量
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax
	
	; 顯示一個窗口
	invoke ShowWindow, hwnd,SW_SHOWNORMAL
	; 刷新一個窗口
	invoke UpdateWindow, hwnd
	
	; 進入了處理消息的循環
	.WHILE TRUE
		; 獲取一條消息
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		
		; 轉換消息 分發消息
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
