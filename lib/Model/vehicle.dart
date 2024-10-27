class AddVehicle {
  String carId;
  String userId;
  String carType;
  String carMake;
  String carModel;
  String registrationNumber;
  int carCapacity;
  double mileage;
  double energyConsumption;
  bool isDefaultVehicle;

  AddVehicle(
      {required this.carId,
      required this.userId,
      required this.carType,
      required this.carMake,
      required this.carModel,
      required this.registrationNumber,
      required this.carCapacity,
      required this.mileage,
      required this.energyConsumption,
      required this.isDefaultVehicle});

  AddVehicle.fromJson(Map<String, Object?> json)
      : this(
          carId: json['carId']! as String,
          userId: json['userId']! as String,
          carType: json['carType']! as String,
          carMake: json['carMake']! as String,
          carModel: json['carModel']! as String,
          registrationNumber: json['registrationNumber']! as String,
          carCapacity: json['carCapacity']! as int,
          mileage: json['mileage']! as double,
          energyConsumption: json['energyConsumption']! as double,
          isDefaultVehicle: json['isDefaultVehicle']! as bool,
        );
  Map<String, Object?> toJson() {
    return {
      'carId': carId,
      'userId': userId,
      'carType': carType,
      'carMake': carMake,
      'carModel': carModel,
      'registrationNumber': registrationNumber,
      'carCapacity': carCapacity,
      'mileage': mileage,
      'energyConsumption': energyConsumption,
      'isDefaultVehicle': isDefaultVehicle,
    };
  }
}
