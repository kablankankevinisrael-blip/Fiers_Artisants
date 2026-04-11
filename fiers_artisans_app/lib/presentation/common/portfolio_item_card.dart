import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/portfolio_model.dart';
import '../../config/theme.dart';

class PortfolioItemCard extends StatefulWidget {
  final PortfolioModel item;
  final bool showDeleteAction;
  final VoidCallback? onDelete;

  const PortfolioItemCard({
    super.key,
    required this.item,
    this.showDeleteAction = false,
    this.onDelete,
  });

  @override
  State<PortfolioItemCard> createState() => _PortfolioItemCardState();
}

class _PortfolioItemCardState extends State<PortfolioItemCard> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  bool get _showCursorArrows {
    final platform = defaultTargetPlatform;
    final isPhonePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    if (kIsWeb) {
      // On mobile browsers (Android/iOS), hide arrows and keep tactile swipe.
      return !isPhonePlatform;
    }

    // On native apps, keep arrows only for desktop platforms.
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  Future<void> _goToImage(int index) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant PortfolioItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _currentImageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrice = widget.item.price != null;
    final hasDescription =
        widget.item.description != null &&
        widget.item.description!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildImageArea(theme)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 72;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasDescription && !compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.item.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: hasPrice
                                ? Text(
                                    Formatters.fcfa(widget.item.price!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          if (widget.showDeleteAction)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              onPressed: widget.onDelete,
                              tooltip: 'Supprimer',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(ThemeData theme) {
    if (widget.item.imageUrls.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.photo_outlined, size: 40)),
      );
    }

    final hasMultiple = widget.item.imageUrls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        hasMultiple
            ? PageView.builder(
                controller: _pageController,
                itemCount: widget.item.imageUrls.length,
                onPageChanged: (index) {
                  if (!mounted) return;
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return _NetworkImage(url: widget.item.imageUrls[index]);
                },
              )
            : _NetworkImage(url: widget.item.imageUrls.first),
        if (hasMultiple)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${widget.item.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (hasMultiple && _showCursorArrows)
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CarouselArrowButton(
                icon: Icons.chevron_left,
                tooltip: 'Image precedente',
                onPressed: _currentImageIndex > 0
                    ? () => _goToImage(_currentImageIndex - 1)
                    : null,
              ),
            ),
          ),
        if (hasMultiple && _showCursorArrows)
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CarouselArrowButton(
                icon: Icons.chevron_right,
                tooltip: 'Image suivante',
                onPressed: _currentImageIndex < widget.item.imageUrls.length - 1
                    ? () => _goToImage(_currentImageIndex + 1)
                    : null,
              ),
            ),
          ),
        if (hasMultiple)
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.item.imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentImageIndex == index ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CarouselArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 16,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;

  const _NetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      ),
    );
  }
}
