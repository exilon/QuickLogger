#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY ["QuickLogger.Sample.ASPNetCore/QuickLogger.Sample.ASPNetCore.csproj", "QuickLogger.Sample.ASPNetCore/"]
COPY ["QuickLogger.Extensions.Wrapper/QuickLogger.Extensions.Wrapper.csproj", "QuickLogger.Extensions.Wrapper/"]
COPY ["QuickLogger/QuickLogger.NetStandard.csproj", "QuickLogger/"]
COPY ["QuickLogger.NetStandard.Abstractions/QuickLogger.NetStandard.Abstractions.csproj", "QuickLogger.NetStandard.Abstractions/"]
COPY ["QuickLogger.Extensions.NetCore/QuickLogger.Extensions.NetCore.csproj", "QuickLogger.Extensions.NetCore/"]
RUN dotnet restore "QuickLogger.Sample.ASPNetCore/QuickLogger.Sample.ASPNetCore.csproj"
COPY . .
WORKDIR "/src/QuickLogger.Sample.ASPNetCore"
RUN dotnet build "QuickLogger.Sample.ASPNetCore.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "QuickLogger.Sample.ASPNetCore.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
RUN apt-get update && \
    apt-get install -y --allow-unauthenticated libc6-dev
ENTRYPOINT ["dotnet", "QuickLogger.Sample.ASPNetCore.dll"]