import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

// Estos chismosos nos dirán en la consola si Astro sí está leyendo tu .env
console.log("URL de Supabase:", supabaseUrl);
console.log("Llave de Supabase:", supabaseAnonKey ? "Sí hay llave" : "No hay llave");

export const supabase = createClient(supabaseUrl, supabaseAnonKey);