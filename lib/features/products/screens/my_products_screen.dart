import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

class MyProductsScreen extends ConsumerWidget {
  final bool activeOnly;
  const MyProductsScreen({super.key, this.activeOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = activeOnly
        ? ref.watch(myActiveProductsProvider)
        : ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _AppBar(title: activeOnly ? 'Listados activos' : 'Mis productos'),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, st) => Center(
          child: Text('Error al cargar tus productos',
              style: GoogleFonts.manrope(color: AppTheme.error)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppTheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    activeOnly
                        ? 'No tienes productos activos'
                        : 'Aún no has publicado nada',
                    style: GoogleFonts.notoSerif(
                        fontSize: 20, color: AppTheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    activeOnly
                        ? 'Activa algún producto desde "Mis productos"'
                        : '¡Empieza publicando tu primer producto!',
                    style: GoogleFonts.manrope(
                        color: AppTheme.onSurfaceVariant)),
                  if (!activeOnly) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/publicar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text('Publicar producto',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.only(
              top: 96,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: products.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _ProductTile(
              product: products[i],
              onRefresh: () {
                ref.invalidate(myProductsProvider);
                ref.invalidate(myActiveProductsProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/publicar'),
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Nuevo',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(179),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppTheme.primary,
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  final VoidCallback onRefresh;

  const _ProductTile({required this.product, required this.onRefresh});

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final newStatus = product.status == 'active' ? 'paused' : 'active';
    try {
      await ref
          .read(productServiceProvider)
          .updateStatus(product.id, newStatus);
      ref.invalidate(myProductsProvider);
      ref.invalidate(myActiveProductsProvider);
      ref.invalidate(activeProductsProvider);
    } catch (e) {
      if (e is AuthException && context.mounted) {
        await ref.read(authServiceProvider).signOut();
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cambiar el estado. Inténtalo de nuevo.',
                style: GoogleFonts.manrope()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar producto',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que quieres eliminar "${product.title}"?',
            style: GoogleFonts.manrope()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar',
                  style: GoogleFonts.manrope(
                      color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(productServiceProvider).softDelete(product.id);
        ref.invalidate(myProductsProvider);
        ref.invalidate(myActiveProductsProvider);
        ref.invalidate(activeProductsProvider);
      } catch (e) {
        if (e is AuthException && context.mounted) {
          await ref.read(authServiceProvider).signOut();
          return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo eliminar el producto. Inténtalo de nuevo.',
                  style: GoogleFonts.manrope()),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = product.status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Contenido principal
          Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: product.coverImageUrl != null
                      ? Image.network(
                          product.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                              color: AppTheme.surfaceContainerHigh,
                              child: const Icon(Icons.image_outlined,
                                  color: AppTheme.onSurfaceVariant)),
                        )
                      : Container(
                          color: AppTheme.surfaceContainerHigh,
                          child: const Icon(Icons.image_outlined,
                              color: AppTheme.onSurfaceVariant)),
                ),
              ),
              // Datos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: GoogleFonts.notoSerif(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.priceLabel} / ${product.unit}',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusBadge(status: product.status),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Barra de acciones
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: AppTheme.outlineVariant.withAlpha(80))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Editar',
                    onTap: () =>
                        context.push('/editar-producto/${product.id}'),
                  ),
                ),
                Container(
                    width: 1, height: 36, color: AppTheme.outlineVariant.withAlpha(80)),
                Expanded(
                  child: _ActionBtn(
                    icon: isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    label: isActive ? 'Pausar' : 'Activar',
                    onTap: () => _toggleStatus(context, ref),
                    color: isActive ? AppTheme.secondary : AppTheme.primary,
                  ),
                ),
                Container(
                    width: 1, height: 36, color: AppTheme.outlineVariant.withAlpha(80)),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.delete_outline,
                    label: 'Eliminar',
                    onTap: () => _delete(context, ref),
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'active' => ('Activo', AppTheme.tertiaryFixed, AppTheme.tertiary),
      'paused' => ('Pausado', AppTheme.surfaceContainerHigh, AppTheme.onSurfaceVariant),
      _ => ('Inactivo', AppTheme.surfaceContainerHigh, AppTheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
