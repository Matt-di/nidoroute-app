import 'package:logging/logging.dart';
import 'package:nito_reverb/nito_reverb.dart';
import '../config/app_config.dart';

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();
  factory ReverbService() => _instance;
  ReverbService._internal();

  final _log = Logger('ReverbService');
  NitoReverbClient? _client;
  String? _currentToken;

  bool get isConnected => _client?.isConnected ?? false;
  
  /// Stream of connection states for the UI to react to
  Stream<NitoReverbConnectionState>? get stateStream => _client?.stateStream;

  Future<void> connect(String token) async {
    if (_client != null && isConnected && _currentToken == token) return;
    
    if (_client != null && _currentToken != token) {
      disconnect();
    }

    try {
      _currentToken = token;
      
      final config = NitoReverbConfig(
        host: AppConfig.reverbHost,
        port: AppConfig.reverbPort,
        key: AppConfig.reverbKey,
        encrypted: AppConfig.reverbScheme == 'wss',
      );

      // Professional Auth with proper headers
      final auth = HttpNitoReverbAuth(
        url: '${AppConfig.baseUrl}/broadcasting/auth',
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _client = NitoReverbClient(config: config, auth: auth);
      
      _client!.stateStream.listen((state) {
        _log.info('Connection state changed: $state');
      });

      await _client!.connect();
      
      _log.info('NitoReverb: Professional Client Initialized for ${AppConfig.reverbHost}');
    } catch (e) {
      _log.severe('NitoReverb: Initialization Failed', e);
      _client = null;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _currentToken = null;
  }

  /// Listen to a public channel
  void public(String channel, String event, Function(dynamic) callback) {
    if (_client == null) {
      _log.warning('Attempted to listen to public channel $channel before init');
      return;
    }
    _listenToChannel(_client!.public(channel), event, callback);
  }

  /// Listen to a private channel
  void private(String channel, String event, Function(dynamic) callback) {
    if (_client == null) {
      _log.warning('Attempted to listen to private channel $channel before init');
      return;
    }
    _listenToChannel(_client!.private(channel), event, callback);
  }

  /// Listen to a presence channel
  void presence(String channel, String event, Function(dynamic) callback) {
    if (_client == null) {
      _log.warning('Attempted to listen to presence channel $channel before init');
      return;
    }
    _listenToChannel(_client!.presence(channel), event, callback);
  }

  /// Shared listing logic with event normalization
  void _listenToChannel(NitoReverbChannel channel, String event, Function(dynamic) callback) {
    channel.dataOn(event).listen((data) {
      callback(data);
    });
    
    // Handle leading dots (Laravel namespace issue)
    final normalizedEvent = event.startsWith('.') ? event.substring(1) : event;
    if (normalizedEvent != event) {
      channel.dataOn(normalizedEvent).listen((data) {
        callback(data);
      });
    }
  }

  /// Send client-side whisper event
  void whisper(String channel, String event, dynamic data) {
    if (_client == null) return;
    _client!.whisper(channel, event, data);
  }

  void leave(String channel) {
    _log.info('Leaving channel $channel');
    // Using simple unsubscription which handles prefixing internally if implementing using NitoReverbClient's unsubscribe methods correctly
    // However, NitoReverbClient.unsubscribe takes exact name, so we rely on the user passing the correct name 
    // OR we can make it smart. For now, let's just pass it through.
    _client?.unsubscribe(channel);
    
    // Also try removing with prefixes just in case, or rely on correct usage. 
    // Since our private/public methods abstract the prefixes, we should matching logic here?
    // Actually, client.unsubscribe simply sends the unsubscribe event.
  }
}
