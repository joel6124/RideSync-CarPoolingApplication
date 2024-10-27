class UserDetails {
  String id;
  String name;
  String email;
  String imgURL;
  String gender;
  String phone;

  UserDetails(
      {required this.id,
      required this.name,
      required this.email,
      required this.imgURL,
      required this.gender,
      required this.phone});

  // UserDetails.fromJson(Map<String, Object?> json) :  this(id: json['id']! as String,name: json['name'] as String,email: : json['email'] as String,imgURL: : json['imgURL'] as String,gender: : json['gender'] as String,phone: : json['phone'] as String);
}
