-- =====================================================================
-- Sonikoner · Configuración de seguridad para la tabla `citas`
-- Cómo usarlo: Supabase → SQL Editor → pega todo esto → Run.
-- Se puede correr varias veces sin romper nada.
-- =====================================================================

-- 1. Tabla (solo se crea si todavía no existe)
create table if not exists public.citas (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  nombre_cliente text not null,
  whatsapp       text not null,
  fecha          date not null,
  hora           time not null,
  idea_tatuaje   text,
  estado         text not null default 'pendiente'
);

-- 2. Validaciones dentro de la base de datos (aunque alguien se salte el formulario)
alter table public.citas drop constraint if exists citas_estado_valido;
alter table public.citas add constraint citas_estado_valido
  check (estado in ('pendiente', 'confirmado', 'cancelado'));

alter table public.citas drop constraint if exists citas_whatsapp_valido;
alter table public.citas add constraint citas_whatsapp_valido
  check (whatsapp ~ '^[0-9]{10}$');

alter table public.citas drop constraint if exists citas_hora_valida;
alter table public.citas add constraint citas_hora_valida
  check (hora in ('11:00', '14:00', '17:00'));

-- 3. No puede haber dos citas activas en el mismo día y hora.
--    Las canceladas no cuentan, así el horario se libera.
--    OJO: si ya tienes citas duplicadas esto fallará; borra/cancela una antes.
create unique index if not exists citas_fecha_hora_activa
  on public.citas (fecha, hora)
  where estado <> 'cancelado';

-- 4. Row Level Security: nadie lee nada a menos que una regla lo permita
alter table public.citas enable row level security;

-- Reglas viejas de la primera versión (dejaban ver todas las citas a cualquiera)
drop policy if exists "Permitir lectura pública de citas"    on public.citas;
drop policy if exists "Permitir insertar citas desde la web" on public.citas;
drop policy if exists "Publico puede leer todo"      on public.citas;
drop policy if exists "Clientes pueden agendar"      on public.citas;
drop policy if exists "Admin puede ver citas"        on public.citas;
drop policy if exists "Admin puede actualizar citas" on public.citas;
drop policy if exists "Admin puede borrar citas"     on public.citas;

-- Visitantes (anon): SOLO pueden crear citas nuevas en estado pendiente y a futuro.
create policy "Clientes pueden agendar"
  on public.citas for insert
  to anon
  with check (estado = 'pendiente' and fecha >= current_date);

-- Sergio (usuario logueado): puede ver, actualizar y borrar.
create policy "Admin puede ver citas"
  on public.citas for select
  to authenticated
  using (true);

create policy "Admin puede actualizar citas"
  on public.citas for update
  to authenticated
  using (true)
  with check (true);

create policy "Admin puede borrar citas"
  on public.citas for delete
  to authenticated
  using (true);

-- 5. El calendario público solo necesita saber qué horas están ocupadas,
--    NO los nombres ni teléfonos. Esta función devuelve únicamente eso.
create or replace function public.horas_ocupadas(dia date)
returns table (hora time)
language sql
stable
security definer
set search_path = public
as $$
  select c.hora
  from public.citas c
  where c.fecha = dia
    and c.estado <> 'cancelado';
$$;

revoke all on function public.horas_ocupadas(date) from public;
grant execute on function public.horas_ocupadas(date) to anon, authenticated;

-- =====================================================================
-- PASOS MANUALES EN EL DASHBOARD DE SUPABASE (importante):
--  a) Authentication → Users → "Add user": crea el usuario de Sergio
--     con su correo y una contraseña fuerte.
--  b) Authentication → Sign In / Providers → desactiva "Allow new users
--     to sign up". Si no, cualquiera podría crearse una cuenta y ver
--     las citas (las reglas de arriba dan acceso a todo usuario logueado).
-- =====================================================================
