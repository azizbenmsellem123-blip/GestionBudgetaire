class UserModel {
  final String uid;
  double solde;

  UserModel({required this.uid, this.solde = 0});

  Map<String, dynamic> toMap() {
    return {'solde': solde};
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      solde: map['solde'] ?? 0,
    );
  }
}
