import 'package:environment_sensors/environment_sensors.dart';

class LevelCalculator{
  static Future<void> checkSensorsAvaileble() async {
    final environmentSensors = EnvironmentSensors();
    print(await environmentSensors.getSensorAvailable(SensorType.Pressure));
    print(await environmentSensors.getSensorAvailable(SensorType.Light));
  }


}