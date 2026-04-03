import 'package:apapane/models/product/product.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/view_models/purchase_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchase_providers.dart';

class PurchasePage extends ConsumerWidget {
  const PurchasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(purchaseViewModelProvider);
    final mainViewModel = ref.watch(mainViewModelProvider);

    if (!mainViewModel.hasSyncedAccount) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ストア'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '購入や定期購入を管理するには、保護者がログインしてください。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ストア',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
          ),
        ),
        child: SafeArea(
          child: viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildStoreInfo(),
                    const SizedBox(height: 32),
                    _buildProductList(viewModel),
                    const SizedBox(height: 32),
                    _buildEntitlements(viewModel),
                    const SizedBox(height: 32),
                    _buildRestoreButton(viewModel),
                    if (viewModel.isSubscriptionActive) ...[
                      const SizedBox(height: 16),
                      _buildManageSubscriptionButton(viewModel, context),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '保護者向け購入メニュー',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3700B3),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '購入内容はサーバーで確認され、保護者アカウントに同期されます。再インストールや機種変更のときは「購入を復元」を使ってください。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(PurchaseViewModel viewModel) {
    if (viewModel.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          '販売中の商品がまだありません。App Store Connect または Play Console の設定を確認してください。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: viewModel.products
              .map((product) => _buildProductItem(product, viewModel))
              .toList(),
        );
      },
    );
  }

  Widget _buildProductItem(Product product, PurchaseViewModel viewModel) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: product.isSubscription
                          ? [
                              const Color(0xFFE6E6FA),
                              const Color(0xFFF0E68C),
                              const Color(0xFFFFB6C1),
                            ]
                          : [
                              const Color(0xFFE0FFFF),
                              const Color.fromARGB(255, 152, 251, 229),
                              const Color(0xFFFFD700),
                            ],
                    ),
                  ),
                  child: Center(
                    child: product.isSubscription
                        ? Image.asset(
                            'assets/images/premium.PNG',
                            fit: BoxFit.contain,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              'assets/images/kohaku.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6B6B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        viewModel.isSubscriptionActive && product.isSubscription
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: viewModel.isPurchaseInProgress
                                    ? null
                                    : () => viewModel.purchaseProduct(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  product.price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (product.isSubscription)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'プレミアム',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntitlements(PurchaseViewModel viewModel) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const ListTile(
            title: Text(
              '現在の利用状況',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 67, 67, 67),
              ),
            ),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom:
                    Radius.circular(viewModel.isSubscriptionActive ? 0 : 15),
              ),
            ),
            tileColor: const Color.fromARGB(255, 223, 250, 243),
            leading: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/kohaku.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            title: const Text('ものがたりコイン'),
            trailing: Text('x${viewModel.coinCount}'),
          ),
          if (viewModel.isSubscriptionActive)
            ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              tileColor: const Color.fromARGB(255, 245, 223, 250),
              leading: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/premium.PNG'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: const Text('プレミアムパス'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(PurchaseViewModel viewModel) {
    return viewModel.isRestoreLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        : ElevatedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('購入を復元'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6200EE),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            onPressed: viewModel.restorePurchases,
          );
  }

  Widget _buildManageSubscriptionButton(
    PurchaseViewModel viewModel,
    BuildContext context,
  ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.open_in_new),
      label: const Text('定期購入を管理'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => viewModel.manageSubscription(context),
    );
  }
}
