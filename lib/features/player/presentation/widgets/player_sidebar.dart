import 'package:flutter/material.dart';

import '../../../media_detail/domain/models/media_detail.dart';

/// 选集面板背后的半透明遮罩（点击关闭）
class PlayerSidebarOverlay extends StatelessWidget {
  const PlayerSidebarOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(color: Colors.black54),
      ),
    );
  }
}

/// 右侧 300px 选集面板（Tab 标题 + 剧集列表）
class PlayerSidebar extends StatelessWidget {
  const PlayerSidebar({
    super.key,
    required this.open,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.scrollController,
    required this.onSelect,
  });

  final bool open;
  final List<EpisodeItem> episodes;
  final int currentEpisodeIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: open ? 300 : 0,
        color: const Color(0xFF121212),
        child: ClipRect(
          child: DefaultTabController(
            length: 1,
            child: Column(
              children: [
                Material(
                  color: const Color(0xFF1F1F1F),
                  child: TabBar(
                    tabAlignment: TabAlignment.center,
                    isScrollable: true,
                    tabs: [Tab(text: '选集 (${episodes.length})')],
                  ),
                ),
                Expanded(
                  child: episodes.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无选集',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : Scrollbar(
                          controller: scrollController,
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: episodes.length,
                            itemBuilder: (context, index) {
                              final ep = episodes[index];
                              final isCurrent = index == currentEpisodeIndex;

                              return InkWell(
                                onTap: () => onSelect(index),
                                child: SizedBox(
                                  height: 64,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    color: isCurrent
                                        ? primaryColor
                                        : const Color(0xFF121212),
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        ep.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
