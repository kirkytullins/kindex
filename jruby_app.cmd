@echo off
setlocal enabledelayedexpansion
FOR /r %~dps0 %%i IN (*.jar) DO SET CLASSPATH=%%i;!CLASSPATH!
@echo %CLASSPATH%
java -version:"1.6* 1.7*"  -Xmx1G -XX:+PerfDisableSharedMem -Djruby.compat.version=1.9 -Djava.io.tmpdir=%TEMP%  org.jruby.Main -r rubygems %*
