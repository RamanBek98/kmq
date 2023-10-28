class UserModel {
  final String uid;
  final String username;
  final String? profilePicturePath;

  UserModel({required this.uid, required this.username, this.profilePicturePath});

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'profilePicturePath': profilePicturePath,
  };

  static UserModel fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      profilePicturePath: data['profilePicturePath'] as String?,
    );
  }
}

class GameRoom {
  final String roomId;
  final String hostId;
  final String hostName;
  final String? hostProfilePicturePath;
  final List<String> players; // Now contains only UIDs of the players.
  final int maxPlayers;
  final String status;
  final String? currentSongId;
  final DateTime timestamp;
  final int currentVideoIndex;
  final int currentRound;
  final String gameStatus;

  GameRoom({
    required this.roomId,
    required this.hostId,
    required this.hostName,
    this.hostProfilePicturePath,
    required this.players,
    required this.maxPlayers,
    required this.status,
    this.currentSongId,
    required this.timestamp,
    required this.currentVideoIndex,
    required this.currentRound,
    required this.gameStatus,
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'hostId': hostId,
    'hostName': hostName,
    'hostProfilePicturePath': hostProfilePicturePath,
    'players': players, // Storing the UIDs as a list.
    'maxPlayers': maxPlayers,
    'status': status,
    'currentSongId': currentSongId,
    'timestamp': timestamp.toIso8601String(),
    'currentVideoIndex': currentVideoIndex,
    'currentRound': currentRound,
    'gameStatus': gameStatus,
  };

  static GameRoom fromMap(Map<String, dynamic> data) {
    return GameRoom(
        roomId: data['roomId'] ?? '',
        hostId: data['hostId'] ?? '',
        hostName: data['hostName'] ?? '',
        hostProfilePicturePath: data['hostProfilePicturePath'] as String?,
        players: List<String>.from(data['players'] ?? []),
        maxPlayers: data['maxPlayers'] ?? 0,
        status: data['status'] ?? '',
        currentSongId: data['currentSongId'] as String?,
        timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
        currentVideoIndex: data['currentVideoIndex'] ?? 0,
        currentRound: data['currentRound'] ?? 0,
        gameStatus: data['gameStatus'] ?? ''
    );
  }
}
