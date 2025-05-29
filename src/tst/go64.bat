@setlocal
call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
F:\harbour_msvc\bin\win\msvc64\hbmk2 http_connector_tst_msvc.hbp -comp=msvc64
@endlocal
