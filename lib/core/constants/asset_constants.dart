/// 资源路径常量
class AssetConstants {
  AssetConstants._();

  // 基础路径
  static const String _imagesBase = 'assets/images';
  static const String _animationsBase = 'assets/animations';

  // 图片路径
  static const String petsPath = '$_imagesBase/pets';
  static const String itemsPath = '$_imagesBase/items';
  static const String backgroundsPath = '$_imagesBase/backgrounds';
  static const String uiPath = '$_imagesBase/ui';

  // 动画路径
  static const String rivePath = '$_animationsBase/rive';
  static const String lottiePath = '$_animationsBase/lottie';

  // 占位图
  static const String placeholderPet = '$uiPath/placeholder_pet.png';
  static const String placeholderAvatar = '$uiPath/placeholder_avatar.png';

  // Logo
  static const String logo = '$uiPath/logo.png';
  static const String logoText = '$uiPath/logo_text.png';

  // 预设宠物
  static const String defaultCat = '$petsPath/default_cat.png';
  static const String defaultDog = '$petsPath/default_dog.png';
  static const String defaultRabbit = '$petsPath/default_rabbit.png';

  // Lottie 动画
  static const String heartAnimation = '$lottiePath/heart.json';
  static const String starAnimation = '$lottiePath/star.json';
  static const String confettiAnimation = '$lottiePath/confetti.json';
  static const String loadingAnimation = '$lottiePath/loading.json';

  // Rive 动画
  static const String petIdleRive = '$rivePath/pet_idle.riv';
  static const String petEatRive = '$rivePath/pet_eat.riv';
  static const String petHappyRive = '$rivePath/pet_happy.riv';
}
