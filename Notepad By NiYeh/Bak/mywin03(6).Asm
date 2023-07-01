;********************************************
; 程序作者 : 逆葉
; 開發日期 : 2023年6月7日
; 功能描述 : 筆記本應用程序
; 注意事項 : 
; 更新歷史 : 
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
   ClassName		db "MainWinClass",0			; 窗口類名
   AppName 			db "Notepad 逆葉",0 		; 應用程序標題名
   AboutApp 		db "這是逆葉用彙編語言所開發Win32的記事本", 0
   
   editClass 		db "edit", 0
   
   ; 調用公共對話框所必要訊息
   szFitler			db "文件(*.txt)", 0, "*.txt", 0, "所有文件(*.*)", 0, "*.*", 0, 0
   szDefExt 		db "txt", 0
   
   ; "打開" 和 "保存" 文件的標題
   szOpenTitle		db "Open", 0
   szSaveTitle		db "Save", 0
   
.data?
   hInstance 		HINSTANCE 	?			; 應用程序的句柄
   CommandLine 		LPSTR 		?			; 程序的命令行參數字符串指針
   hEdit			HWND		?			; 文本編輯框的句柄
   strFile			db MAX_PATH	dup (?)		; 保存公共對話框獲取的文件名
   
   strFileBuf		db 81920	dup (?)

.code
	; 圖標
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
;**********************************************************************************************
	; 填充windows的窗口結構體
	mov   wc.cbSize,SIZEOF WNDCLASSEX				; 表示窗口結構體的總大小
	mov   wc.style, CS_HREDRAW or CS_VREDRAW		; 窗口類型
	mov   wc.lpfnWndProc, OFFSET WndProc			; 傳遞消息處理函數的指針
	mov   wc.cbClsExtra,NULL						; 窗口類的附加數據
	mov   wc.cbWndExtra,NULL						; 窗口的附加數據
	
	push  hInstance									; 傳遞程序的實例句柄給窗口類
	pop   wc.hInstance
	
	mov   wc.hbrBackground,COLOR_BTNFACE+1			; 創建窗口時的默認背景顏色

	mov   wc.lpszMenuName,IDR_MENU					; 為此窗口建立一個主菜單
	mov   wc.lpszClassName,OFFSET ClassName			; 窗口類的名稱
	
	invoke LoadIcon,NULL,IDI_APPLICATION			; 為此窗口建立一個圖標
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW				; 指定窗口上的鼠標指針類型
	mov   wc.hCursor,eax
;**********************************************************************************************
	
	; 向Windows註冊一個窗口
	invoke RegisterClassEx, addr wc
	
	; 創建一個窗口 然後把窗口句柄賦值給hwnd變量
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,450,650,NULL,NULL,\
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
		invoke LoadIcon, hInstance,App_Icon		; 為此窗口建立一個圖標
		invoke SendMessage, hWnd, WM_SETICON, ICON_BIG, eax
		
		; 創建一個文本編輯視窗
		invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset editClass, NULL, WS_MAXIMIZE OR \
							ES_AUTOHSCROLL OR ES_AUTOVSCROLL OR ES_MULTILINE OR \
							WS_CHILDWINDOW OR WS_VISIBLE OR WS_VSCROLL OR WS_HSCROLL,\
		 					0, 0, 1000, 480, hWnd, NULL, hInstance, NULL
		mov hEdit, eax
		
		; invoke ColorCorrectPalette,
		
	.ELSEIF	uMsg == WM_SIZE
		; 獲取當前視窗的坐標 x, y, top, bottom
		; invoke GetWindowRect, hWnd, addr winRect
		invoke GetClientRect, hWnd, addr winRect

		; 計算出視窗的新寬度和高度
		mov eax, winRect.right
		sub eax, winRect.left
		; sub eax, 15
		mov editWidth, eax
		
		mov eax, winRect.bottom
		sub eax, winRect.top
		; sub eax, 40
		mov editHeight, eax
		
		; 改變文本編輯框的寬度和高度
		invoke MoveWindow, hEdit, 0, 0, editWidth, editHeight, TRUE
		
	.ELSEIF	uMsg == WM_COMMAND
		mov	eax, wParam

		.if ax == IDM_Open_File
			; 文件 -> 打開
			; 初始化公共對話框結構體
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
			
			; 調用打開文件的公共對話框 獲取文件路徑
			invoke GetOpenFileName, addr ofn
			.if eax == TRUE
				; invoke MessageBox, hWnd, offset strFile, addr AppName, MB_OK or MB_ICONINFORMATION
				; 對這個文件進行處理
				invoke CreateFile, offset strFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				.if eax != INVALID_HANDLE_VALUE
					invoke RtlZeroMemory, addr ofn, sizeof ofn
					;invoke RtlZeroMemory, offset strFile, sizeof strFile
					mov hFile, eax
					; 讀取文件內容到緩衝區strFileBuf中
					invoke ReadFile, hFile, offset strFileBuf, sizeof strFileBuf, addr bytesRead, NULL
					; 清空原本的文件內容 然後將strFileBuf的內容顯示到文本框中
					invoke SendMessage,	hEdit, WM_CLEAR, 0, 0
					invoke SetWindowText, hEdit, offset strFileBuf
					; 關閉當前的文件句柄
					invoke CloseHandle,	hFile
				.endif
			.endif
			
		.elseif ax == IDM_Save_File
			; 文件 -> 保存
			; 初始化公共對話框結構體
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
			
			; 調用保存文件的公共對話框 獲取文件路徑
			invoke GetSaveFileName, addr ofn
			.if eax == TRUE
				; invoke MessageBox, hWnd, offset strFile, addr AppName, MB_OK or MB_ICONINFORMATION
				; 打開文件
				invoke CreateFile, offset strFile, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
				.if eax != INVALID_HANDLE_VALUE
					; 獲取文本框的內容
					mov hFile, eax
					invoke RtlZeroMemory, offset strFileBuf, sizeof	strFileBuf
					invoke GetWindowTextLength, hEdit
					mov textLen, eax
					invoke GetWindowText, hEdit, offset strFileBuf, sizeof strFileBuf
					
					; 將文本內容寫入文件
					invoke WriteFile, hFile, offset strFileBuf, textLen,addr bytesWrite, NULL
					invoke CloseHandle, hFile
				.endif
			.endif
			
			; 對這個文件進行處理
		
		.elseif ax == IDM_File_Exit
			; 文件 -> 退出應用程序
			invoke DestroyWindow, hWnd
			invoke PostQuitMessage,NULL
			
		.elseif ax == IDM_Edit_Undo
			; 編輯 -> 撤銷 
			invoke SendMessage, hEdit, EM_UNDO, 0, 0
			
		.elseif ax == IDM_Edit_Redo
			; 編輯 -> 重做
			invoke SendMessage, hEdit, EM_REDO, 0, 0
			
		.elseif ax == IDM_Edit_Cut
			; 編輯 -> 剪切
			invoke SendMessage, hEdit, WM_CUT, 0, 0
			
		.elseif ax == IDM_Edit_Copy
			; 編輯 -> 複製
			invoke SendMessage, hEdit, WM_COPY, 0, 0
			
		.elseif ax == IDM_Edit_Paste
			; 編輯 -> 粘貼
			invoke SendMessage, hEdit, WM_PASTE, 0, 0
		
		.elseif ax == IDM_Help_About
			; 菜單 -> 關於
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
