unit CB.AI.Registry;

interface

uses
  Spring, Spring.Collections,
  CB.Settings.Types, CB.Network.Types,
  CB.AI.Interaction;

const
  CAuthorizationKeyPlaceholder = '$(AUTH)';

var
  GSerializers: IDictionary<TCBAIEngineType, IAISerializer>;
  GNetworkHeaderProvider: IMultiMap<TCBAIEngineType, TNetworkHeader>;

implementation

initialization
  GSerializers := TCollections.CreateDictionary<TCBAIEngineType, IAISerializer>;
  GNetworkHeaderProvider := TCollections.CreateMultiMap<TCBAIEngineType, TNetworkHeader>;
end.
