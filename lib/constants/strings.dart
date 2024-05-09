//packages
import 'package:uuid/uuid.dart';

//apapane titles
const String lowerTitle = 'apapane';
const String startUpperTitle = 'Apapane';
const String selectTitle = 'えらんでね';

//titles
const String makeStoryTitle = 'おはなしをつくる';
const String noStoryTitle = 'おはなしがありません';

//texts
const String startAdventureText = 'ぼうけんをはじめる';
const String endButtonText = 'おしまい';
const String archiveText = "ぼうけんのきろく";
const String mailAddressText = 'メールアドレス';
const String passwordText = 'パスワード';
const String signUpText = 'とうろく';
const String loginText = 'ログイン';
const String createText = 'つくる';
const String publicText = 'みんなのぼうけん';
const String storyText = 'きみのぼうけん';
const String profileText = 'プロフィール';
const String logoutText = 'ログアウト';
const String loadingText = '読み込み中';
const String saveText = 'きろくする';
const String noText = 'いいえ';
const String yesText = 'はい';
const String muteText = 'ミュート';
const String reloadText = 'よみこむ';
const String downloadingText = 'きろくちゅう';
const String deleteText = 'さくじょ';
const String cancelText = 'キャンセル';
const String chatHintText = 'きみのセカイをつたえよう';
const String youCanSelectText = 'えらんでもできるよ！';
const String editProfileText = 'プロフィールをへんしゅう';
const String followerText = 'フォロワー';
const String followingText = 'フォロー中';
const String favoriteStoryText = 'きみのおきにいり';

//messages
const String userCreatedMsg = 'とうろくかんりょう！';
const String userLoggedInMsg = 'ログインしました！';
const String userLoggedOutMsg = 'ログアウトしました！';
const String makingMSG = 'さくせいちゅう';
const String reloadMSG = 'よみこみちゅう';
const String deleteMSG = 'さくじょちゅう';
const String pleaseWaitMSG = 'ちょっとまってね';

//titlePictures
const List<String> titlePicture = [
  'assets/images/arupaka.png',
  'assets/images/pirate.png',
  'assets/images/boy.png',
  'assets/images/dragon.png',
  'assets/images/dream.png',
  'assets/images/rupan.png',
  'assets/images/girl.png',
  'assets/images/pretty_girl.png',
  'assets/images/dog.png'
];
const String homeImage = 'assets/images/home_image.png';
const String endImage = 'assets/images/end_story_image.png';
const String apapaneImage = 'assets/images/apapane_icon_1.png';
const String archiveImage = 'assets/images/archive_my_story.png';
const String publicImage = 'assets/images/public_stories_image.png';
const String circleIndicatorImage = 'assets/images/circle_indicator_image.png';

//id
String returnUuidV4() {
  const Uuid uuid = Uuid();
  return uuid.v4();
}

//jpg
String returnJpgFileName() => "${returnUuidV4()}.jpg";
