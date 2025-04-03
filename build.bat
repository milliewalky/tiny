@echo off
setlocal enabledelayedexpansion
cd /D "%~dp0"

:: --- unpack arguments -------------------------------------------------------
for %%a in (%*) do set "%%a=1"
if not "%msvc%"=="1" if not "%clang%"=="1" set msvc=1
if not "%release%"=="1" set debug=1
if "%debug%"=="1"   set release=0 && echo [debug mode]
if "%release%"=="1" set debug=0 && echo [release mode]
if "%msvc%"=="1"    set clang=0 && echo [msvc compile]
if "%clang%"=="1"   set msvc=0 && echo [clang compile]
if "%~1"==""                     echo [default mode, assuming `tiny` build] && set tiny=1
if "%~1"=="release" if "%~2"=="" echo [default mode, assuming `tiny` build] && set tiny=1

:: --- unpack command line build arguments ------------------------------------
set auto_compile_flags=
if "%asan%"=="1"    set auto_compile_flags=%auto_compile_flags% -fsanitize=address && echo [asan enabled]

:: --- compile/link line definitions ------------------------------------------
set cl_common=     /I. /I..\third_party\ /nologo /FC /Z7
set clang_common=  -I. -I..\third_party\ -gcodeview -fdiagnostics-absolute-paths -Wall -Wno-unknown-warning-option -Wno-missing-braces -Wno-unused-function -Wno-writable-strings -Wno-unused-value -Wno-unused-variable -Wno-unused-local-typedef -Wno-deprecated-register -Wno-deprecated-declarations -Wno-unused-but-set-variable -Wno-single-bit-bitfield-constant-conversion -Wno-compare-distinct-pointer-types -Wno-initializer-overrides -Wno-incompatible-pointer-types-discards-qualifiers -Xclang -flto-visibility-public-std -D_USE_MATH_DEFINES -Dstrdup=_strdup -Dgnu_printf=printf -ferror-limit=10000
set cl_debug=      call cl /Od /Ob1 /DBUILD_DEBUG=1 %cl_common% %auto_compile_flags%
set cl_release=    call cl /O2 /DBUILD_DEBUG=0 %cl_common% %auto_compile_flags%
set clang_debug=   call clang -g -O0 -DBUILD_DEBUG=1 %clang_common% %auto_compile_flags%
set clang_release= call clang -g -O2 -DBUILD_DEBUG=0 %clang_common% %auto_compile_flags%
set cl_link=       /link /MANIFEST:EMBED /INCREMENTAL:NO /pdbaltpath:%%%%_PDB%%%% /noexp
set clang_link=    -fuse-ld=lld -Xlinker /MANIFEST:EMBED -Xlinker /pdbaltpath:%%%%_PDB%%%% -Xlinker
set cl_out=        /out:
set clang_out=     -o
set cl_natvis=     /NATVIS:
set clang_natvis=  -Xlinker /NATVIS:

:: --- choose compile/link lines ----------------------------------------------
if "%msvc%"=="1"      set compile_debug=%cl_debug%
if "%msvc%"=="1"      set compile_release=%cl_release%
if "%msvc%"=="1"      set compile_link=%cl_link%
if "%msvc%"=="1"      set out=%cl_out%
if "%clang%"=="1"     set compile_debug=%clang_debug%
if "%clang%"=="1"     set compile_release=%clang_release%
if "%clang%"=="1"     set compile_link=%clang_link%
if "%clang%"=="1"     set out=%clang_out%
if "%debug%"=="1"     set compile=%compile_debug%
if "%release%"=="1"   set compile=%compile_release%

:: --- prep directories -------------------------------------------------------
if not exist build mkdir build

:: --- get current git commit id ----------------------------------------------
for /f %%i in ('call git describe --always --dirty')   do set compile=%compile% -DBUILD_GIT_HASH=\"%%i\"
for /f %%i in ('call git rev-parse HEAD')              do set compile=%compile% -DBUILD_GIT_HASH_FULL=\"%%i\"

:: --- build everything -------------------------------------------------------
pushd build
if "%tiny%"=="1" (
  set built=1

  xcopy /d /i /k /y /q ..\SDL3.* . >nul 2>&1

  %compile% ..\tiny_main.c %compile_link% %out%tiny.exe || exit /b 1
)
popd

:: --- warn on no builds ------------------------------------------------------
if "%built%"=="" (
  echo [WARNING] no valid build target specified; must use build target names as arguments to this script, like `build tiny` or `build something_else`.
  exit /b 1
)
