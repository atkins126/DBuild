unit DBuild.Config;

interface

uses
  DBuild.Config.Classes;

type
  TConfig = class
  strict private
    class var FInstance: TDBuildConfig;
    class var FDelphiInstalationPath: string;
  private
    class function YamlFileToConfig: TDBuildConfig; static;
  public
    class function Instance: TDBuildConfig;
    class function DelphiInstalationPath: string;
  end;

implementation

Uses
  Neslib.Yaml,
  Generics.Collections, Registry, Windows, IOUtils, SysUtils, Classes, DBuild.Params, DBuild.Path;

{ TConfig }

class function TConfig.Instance: TDBuildConfig;
var
  Version: string;
begin
  if not Assigned(FInstance) then
  begin
    FInstance := YamlFileToConfig;
    Version := FInstance.Compiler.Version;
    FDelphiInstalationPath := TDBUildPath.New.DelphiInstalation(Version);
    FInstance.Compiler.Version := Version;
    FInstance.Compiler.MSBuild := TDBUildPath.New.MsBuild(FDelphiInstalationPath, FInstance.Compiler.MSBuild);
    TDirectory.CreateDirectory(TDBUildPath.New.Format(FInstance.Compiler.LogOutput));
  end;
  result := FInstance;
end;

class function TConfig.YamlFileToConfig: TDBuildConfig;
var
  Doc: IYamlDocument;
  Node, SourceNode: TYamlNode;
  I, L: Integer;
  Package: TPackage;
begin
  result := TDBuildConfig.Create;
  try
    Doc := TYamlDocument.Load(TDBuildParams.ConfigFileName);
    if Doc.Root.TryGetValue('compile', Node) and Node.IsMapping then
    begin
      result.Compiler.Action := Node.Values['action'].ToString();
      result.Compiler.Config := Node.Values['config'].ToString();
      result.Compiler.Plataform := Node.Values['plataform'].ToString();
      result.Compiler.Version := Node.Values['version'].ToString();
      result.Compiler.BplOutput := Node.Values['bpl_output'].ToString();
      result.Compiler.DcpOutput := Node.Values['dcp_output'].ToString();
      result.Compiler.DcuOutput := Node.Values['dcu_output'].ToString();
      result.Compiler.LogOutput := Node.Values['log_output'].ToString();
    end;
    if Doc.Root.TryGetValue('libraryPath', Node) and Node.IsSequence then
    begin
      for I := 0 to Node.Count - 1 do
        result.LibraryPath.Add(Node.Nodes[I].ToString(''));
    end;
    if Doc.Root.TryGetValue('projects', Node) and Node.IsMapping then
    begin
      for I := 0 to Pred(Node.Count) do
      begin
        Package.Create;

        Package.Name := Node.Elements[I].Key;
        Package.Path := Node.Elements[I].Value.Values['path'].ToString;
        Package.Max_warnings := -1;
        if Node.Elements[I].Value.Contains('max_warnings') then
          Package.Max_warnings := Node.Elements[I].Value.Values['max_warnings'].toInteger;
        if Node.Elements[I].Value.Contains('installed') then
          Package.Installed := Node.Elements[I].Value.Values['installed'].toBoolean;
        if Node.Elements[I].Value.Contains('plataform') then
          Package.Plataform := Node.Elements[I].Value.Values['plataform'].ToString
        else
          Package.Plataform := result.Compiler.Plataform;

        Package.LibraryPath := Node.Elements[I].Value.Values['librarypath'].toBoolean;

        if Doc.Root.TryGetValue('source', SourceNode) and SourceNode.IsSequence then
        begin
          for L := 0 to SourceNode.Count - 1 do
            Package.Source.Add(SourceNode.Nodes[L].ToString(''));
        end;
        result.AddPackage(Package);
      end;
    end;
    if Doc.Root.TryGetValue('QA', Node) and Node.IsMapping then
    begin
      result.Metrics.active := Node.Values['active'].toBoolean(false);
      result.Metrics.OutputExt := Node.Values['output_extension'].ToString();
      result.Metrics.OutputPath := Node.Values['output_path'].ToString();
    end;
  except
    result.Free;
  end;
end;

class function TConfig.DelphiInstalationPath: string;
begin
  result := FDelphiInstalationPath;
end;

end.
