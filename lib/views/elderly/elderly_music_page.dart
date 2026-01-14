import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../../models/music_track_model.dart';

class ElderlyMusicPage extends StatelessWidget {
  const ElderlyMusicPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicViewModel(),
      child: const _ElderlyMusicPageBody(),
    );
  }
}

class _ElderlyMusicPageBody extends StatelessWidget {
  const _ElderlyMusicPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MusicViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: viewModel.isLoading
          ? _buildLoading()
          : RefreshIndicator(
              onRefresh: () => viewModel.loadTracks(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // Error message
                    if (viewModel.errorMessage != null)
                      _buildErrorMessage(viewModel),

                    // Benefits Card
                    _buildBenefitsCard(),

                    const SizedBox(height: 28),

                    // Music Tracks Section
                    _buildMusicSection(context, viewModel),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple[700], strokeWidth: 4),
          const SizedBox(height: 16),
          Text(
            'Loading music...',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.music_note, size: 80, color: Colors.purple[700]),
        const SizedBox(height: 16),
        const Text(
          'Relaxing Music',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Listen to calming music for relaxation',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(MusicViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[900]),
            ),
          ),
          IconButton(
            onPressed: viewModel.clearError,
            icon: Icon(Icons.close, color: Colors.red[700]),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[600]!, Colors.purple[400]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Why Listen to\nRelaxing Music?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildBenefitItem(
            Icons.self_improvement,
            'Helps reduce stress and anxiety',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(Icons.mood, 'Improves mood and relaxation'),
          const SizedBox(height: 16),
          _buildBenefitItem(Icons.bedtime, 'Supports better sleep'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSection(BuildContext context, MusicViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.queue_music, size: 32, color: Colors.grey[800]),
            const SizedBox(width: 12),
            const Text(
              'Music Tracks',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Empty state or track list
        if (viewModel.tracks.isEmpty)
          _buildEmptyState()
        else
          ...viewModel.tracks.asMap().entries.map((entry) {
            int index = entry.key;
            MusicTrack track = entry.value;
            return _buildMusicCard(context, viewModel, track, index);
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.music_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No relaxing music available\nat the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicCard(
    BuildContext context,
    MusicViewModel viewModel,
    MusicTrack track,
    int index,
  ) {
    bool isCurrentTrack = viewModel.currentPlayingIndex == index;
    bool isPlaying = isCurrentTrack && viewModel.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrentTrack ? Colors.purple[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTrack ? Colors.purple[300]! : Colors.grey[300]!,
          width: isCurrentTrack ? 2 : 1,
        ),
        boxShadow: [
          if (isCurrentTrack)
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause Button
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isPlaying ? Colors.purple[700] : Colors.grey[200],
              shape: BoxShape.circle,
              boxShadow: [
                if (isPlaying)
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
              ],
            ),
            child: IconButton(
              onPressed: () => viewModel.togglePlayPause(index),
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: isPlaying ? Colors.white : Colors.grey[700],
              ),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: 20),

          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isCurrentTrack
                        ? Colors.purple[900]
                        : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color: isCurrentTrack
                          ? Colors.purple[700]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      track.formattedDuration,
                      style: TextStyle(
                        fontSize: 18,
                        color: isCurrentTrack
                            ? Colors.purple[700]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isPlaying) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 16,
                        color: Colors.purple[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Now Playing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Play state indicator
          if (isPlaying)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[700],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
