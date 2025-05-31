const express = require('express');
const app = express();
const Stripe = require('stripe');
const stripe = Stripe('sk_test_...'); // La teva secret key de test
app.use(express.json());

// Endpoint per crear SetupIntent (per guardar targeta)
app.post('/create-setup-intent', async (req, res) => {
  const { customerId } = req.body; // Suposem que ja tens un Stripe customerId
  const setupIntent = await stripe.setupIntents.create({
    customer: customerId,
    payment_method_types: ['card'],
  });
  res.send({ clientSecret: setupIntent.client_secret });
});

// Endpoint per guardar paymentMethodId a la teva BBDD (opcional)
app.post('/save-payment-method', async (req, res) => {
  const { userId, paymentMethodId } = req.body;
  // Desa userId <-> paymentMethodId a Supabase (aquí només exemple)
  // await supabase.from('user_cards').insert({ user_id: userId, payment_method_id: paymentMethodId });
  res.send({ ok: true });
});

app.listen(4242, () => console.log('Server running'));