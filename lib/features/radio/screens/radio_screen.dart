import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_radio_service.dart';
import '../../../services/audio_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'radio_management_screen.dart';

/// Radio Screen - Campus Radio Experience (Uses Supabase)
class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseRadioService>().fetchTracks();
      final userId = context.read<AuthProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<SupabaseRadioService>().fetchLikedTracks(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.radioColor,
                      AppColors.radioColor.withValues(alpha: 0.7),
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'MVGR Radio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            // DJ Management Button
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white70),
                              tooltip: 'Manage Radio',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RadioManagementScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _LiveBadge(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Campus music, podcasts & more',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _NowPlayingMini(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tracks Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Tracks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ),

          // Tracks List
          Consumer<SupabaseRadioService>(
            builder: (context, service, _) {
              if (service.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracks = service.approvedTracks;
              if (tracks.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 64, color: context.appColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No tracks available',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text('Check back later!', style: TextStyle(color: context.appColors.textTertiary)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TrackTile(
                      track: tracks[index],
                      isLiked: service.likedTrackIds.contains(tracks[index].id),
                    ),
                    childCount: tracks.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Live Badge
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 4),
          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Now Playing Mini Card
class _NowPlayingMini extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, _) {
        final isPlaying = audioService.isPlaying;
        final currentTrack = audioService.currentTrackTitle;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPlaying ? 'Now Playing' : 'Start Listening',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      currentTrack ?? 'Select a track',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                GestureDetector(
                  onTap: () => audioService.pause(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stop, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Track Tile
class _TrackTile extends StatelessWidget {
  final RadioTrack track;
  final bool isLiked;

  const _TrackTile({required this.track, this.isLiked = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, _) {
        final isCurrentTrack = audioService.currentTrackTitle == track.title;
        final isPlaying = isCurrentTrack && audioService.isPlaying;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrentTrack 
                ? AppColors.radioColor.withValues(alpha: 0.15) 
                : (isDark ? AppColors.clayDark : AppColors.clayLight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark 
                ? ClayShadows.dark(intensity: 0.6)
                : ClayShadows.light(intensity: 0.6),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.radioColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
                child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: track.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.radioColor.withValues(alpha: 0.1)),
                        errorWidget: (context, url, error) => const Icon(Icons.music_note),
                      ),
                    )
                  : Icon(Icons.music_note, color: AppColors.radioColor),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isCurrentTrack ? AppColors.radioColor : context.appColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist ?? 'Unknown Artist',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like button
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppColors.error : context.appColors.textTertiary,
                    size: 22,
                  ),
                  onPressed: () => _handleLike(context),
                ),
                // Play/Pause button
                GestureDetector(
                  onTap: () => _handlePlay(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.radioColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePlay(BuildContext context) {
    if (track.audioUrl.isEmpty) return;
    
    final audioService = context.read<AudioService>();
    
    if (audioService.currentTrackTitle == track.title && audioService.isPlaying) {
      audioService.pause();
    } else {
      audioService.playFromUrl(track.audioUrl, title: track.title, artist: track.artist);
      context.read<SupabaseRadioService>().incrementPlayCount(track.id);
    }
  }

  void _handleLike(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like tracks')),
      );
      return;
    }
    context.read<SupabaseRadioService>().toggleLike(track.id, userId);
  }
}
