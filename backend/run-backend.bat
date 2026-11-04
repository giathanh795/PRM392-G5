@echo off
title Liverpool FC - Player Management System (Backend + SQL Server)
echo ====================================================================
echo   LIVERPOOL FC - PLAYER MANAGEMENT SYSTEM (SPRING BOOT 3)
echo ====================================================================
echo   REST API Server: http://localhost:8080/api/players
echo   User Profile:    http://localhost:8080/api/user/profile
echo   Target Database: Microsoft SQL Server (databaseName=LiverpoolPMS)
echo   Script File:     LiverpoolPMS_SqlServer.sql
echo ====================================================================
cd /d "%~dp0"
mvn spring-boot:run
pause
