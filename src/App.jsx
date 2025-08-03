import { useState } from 'react';
import { supabase } from './supabaseClient.js';

export default function App() {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [message, setMessage] = useState('');

  const handleSignUp = async (e) => {
    e.preventDefault();
    setMessage('');
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) {
      setMessage(error.message);
      return;
    }
    const user = data.user;
    if (user) {
      const { error: insertError } = await supabase.from('users').insert({
        auth_id: user.id,
        first_name: firstName,
        last_name: lastName
      });
      if (insertError) {
        setMessage(insertError.message);
        return;
      }
      setMessage('Sign up successful.');
    } else {
      setMessage('Check your email for confirmation.');
    }
  };

  const handleSignIn = async (e) => {
    e.preventDefault();
    setMessage('');
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      setMessage(error.message);
      return;
    }
    setMessage('Signed in successfully.');
  };

  return (
    <div style={{ maxWidth: '420px', margin: '2rem auto', fontFamily: 'sans-serif' }}>
      <h1>{isSignUp ? 'Sign Up' : 'Sign In'}</h1>
      <form onSubmit={isSignUp ? handleSignUp : handleSignIn} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {isSignUp && (
          <>
            <input placeholder="First name" value={firstName} onChange={(e) => setFirstName(e.target.value)} required />
            <input placeholder="Last name" value={lastName} onChange={(e) => setLastName(e.target.value)} required />
          </>
        )}
        <input type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <input type="password" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <button type="submit">{isSignUp ? 'Create account' : 'Sign in'}</button>
      </form>
      <button onClick={() => setIsSignUp(!isSignUp)} style={{ marginTop: '1rem' }}>
        {isSignUp ? 'Have an account? Sign in' : 'Need an account? Sign up'}
      </button>
      {message && <p style={{ marginTop: '1rem' }}>{message}</p>}
    </div>
  );
}
