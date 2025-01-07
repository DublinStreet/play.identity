FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5002

ENV ASPNETCORE_URLS=http://+:5002

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set environment variables for secrets 
ARG GH_OWNER 
ARG GH_PAT

COPY ["src/Play.Identity.Contracts/Play.Identity.Contracts.csproj", "src/Play.Identity.Contracts/"]
COPY ["src/Play.Identity.Service/Play.Identity.Service.csproj", "src/Play.Identity.Service/"]

# Create a temporary nuget.config file 
RUN echo "<?xml version=\"1.0\" encoding=\"utf-8\"?><configuration><packageSources><add key=\"github\" value=\"https://nuget.pkg.github.com/$GH_OWNER/index.json\" /><add key=\"nuget.org\" value=\"https://api.nuget.org/v3/index.json\" /></packageSources><packageSourceCredentials><github><add key=\"Username\" value=\"USERNAME\" /><add key=\"ClearTextPassword\" value=\"$GH_PAT\" /></github></packageSourceCredentials></configuration>" > nuget.config

#RUN --mount=type=secret,id=GH_OWNER,dst=/GH_OWNER --mount=type=secret,id=GH_PAT,dst=/GH_PAT \
#    dotnet nuget add source --username USERNAME --password `cat /GH_PAT` --store-password-in-clear-text --name github "https://nuget.pkg.github.com/`cat /GH_OWNER`/index.json"

RUN dotnet restore "src/Play.Identity.Service/Play.Identity.Service.csproj" --configfile nuget.config

COPY ./src ./src
WORKDIR "/src/Play.Identity.Service"
RUN dotnet publish "Play.Identity.Service.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Play.Identity.Service.dll"]