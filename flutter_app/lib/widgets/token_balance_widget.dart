import 'package:flutter/material.dart';
import '../services/token_service.dart';

class TokenBalanceWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showLabel;

  const TokenBalanceWidget({
    super.key,
    this.onTap,
    this.showLabel = true,
  });

  @override
  State<TokenBalanceWidget> createState() => _TokenBalanceWidgetState();
}

class _TokenBalanceWidgetState extends State<TokenBalanceWidget> {
  final TokenService _tokenService = TokenService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_tokenService.isPremium) {
      // Premium users see "Premium" badge instead of tokens
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade600,
                  Colors.amber.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Premium',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Free users see token balance
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.toll_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${_tokenService.availableTokens}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  'tokens',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
