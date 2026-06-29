import 'package:equatable/equatable.dart';
import '../entities/entities.dart';

class MyUser extends Equatable {
  final String userID;
  final String email;
  final String name;
  final bool hasActiveCart;

  const MyUser({
    required this.userID,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

  static const empty = MyUser(
    userID: '',
    email: '',
    name: '',
    hasActiveCart: false,
  );

  MyUserEntity toEntity() {
    return MyUserEntity(
      userID: userID,
      email: email,
      name: name,
      hasActiveCart: hasActiveCart,
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userID: entity.userID,
      email: entity.email,
      name: entity.name,
      hasActiveCart: entity.hasActiveCart,
    );
  }

  MyUser copyWith({
    String? userID,
    String? email,
    String? name,
    bool? hasActiveCart,
  }) {
    return MyUser(
      userID: userID ?? this.userID,
      email: email ?? this.email,
      name: name ?? this.name,
      hasActiveCart: hasActiveCart ?? this.hasActiveCart,
    );
  }

  @override
  List<Object?> get props => [userID, email, name, hasActiveCart];
}