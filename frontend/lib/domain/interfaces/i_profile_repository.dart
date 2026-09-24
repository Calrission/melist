import 'package:melist_core/melist_core.dart';

abstract class IProfileRepository {
  Future<UserModel> getMyProfile();
  Future<void> patchMyProfile(PatchProfileBody body);
  Future<PublicProfileModel> getPublicProfile(int profileId);
}
