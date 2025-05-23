import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';
import 'package:parkswap/auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sección de información del usuario
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/1.jpg'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user?.name ?? 'Carlos'} ${user?.surname ?? 'Mendoza Rojas'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'carmendoza@gmail.com',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '+34 678056559',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección de puntos y matrícula (centrada)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Puntos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${user?.points ?? 200}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Matrícula',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        user?.licensePlate ?? 'JNX 7295',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Métodos de pago con imagen visible
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mètode de pagament',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (authProvider.cardInfo != null && authProvider.cardInfo!.isNotEmpty)
              _buildPaymentCard(context, authProvider.cardInfo!),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Afegir nova targeta de pagament'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar a añadir tarjeta
              },
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Resto de las secciones (historial, sobre mi...)
            _buildSectionTitle('Historial de reserves'),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Veure historial complet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar al historial completo
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar perfil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar a edición de perfil
              },
            ),
            const Divider(),
            const SizedBox(height: 16),

            _buildSectionTitle('Sobre mi'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Condicions d\'ús'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar a condiciones de uso
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Política de privacitat'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar a política de privacidad
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Ajuda i suport'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navegar a ayuda
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, String cardInfo) {
    final parts = cardInfo.split('|');
    final cardNumber = parts[0];
    final last4Digits = cardNumber.length > 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Usando un icono como alternativa si la imagen no carga
            Icon(
              Icons.credit_card,
              size: 40,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Targeta acabada en',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '•••• $last4Digits',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showCardOptions(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCardOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Eliminar targeta'),
              onTap: () {
                Navigator.pop(context);
                // Lógica para eliminar tarjeta
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar targeta'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a edición de tarjeta
              },
            ),
          ],
        );
      },
    );
  }
}