/// Configuração do Cloudinary. Os valores padrão apontam para a conta do
/// projeto e podem ser sobrescritos em tempo de build:
/// flutter run --dart-define=CLOUDINARY_CLOUD_NAME=... \
///   --dart-define=CLOUDINARY_UPLOAD_PRESET=...
///
/// O preset é do tipo "unsigned", então nenhum segredo fica no app.
abstract final class CloudinaryConfig {
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'byysbeud',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'academia_avatars',
  );
}
