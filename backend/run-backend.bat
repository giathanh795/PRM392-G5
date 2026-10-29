@echo off
title Liverpool PMS Backend (Spring Boot)
echo =======================================================
echo   STARTING LIVERPOOL PMS BACKEND (SPRING BOOT)
echo   Target: http://localhost:8080/api/players
echo =======================================================
cd /d "%~dp0"
mvn spring-boot:run
pause
