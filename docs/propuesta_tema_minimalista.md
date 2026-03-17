# Propuesta de colores — Tema minimalista

Objetivo: mejorar legibilidad y jerarquía visual usando una paleta sobria (neutros + 1 acento principal).

## Principios

- Fondo limpio con alto contraste para texto.
- Menos colores saturados para reducir ruido visual.
- Un solo color de acento para acciones importantes.
- Estados semánticos claros (éxito, error, advertencia).

## Paleta (modo claro)

- **Primary**: `#334155`
- **Secondary**: `#334155`
- **Accent (acciones)**: `#2563EB`
- **Background**: `#F8FAFC`
- **Card**: `#FFFFFF`
- **Texto principal**: `#0F172A`
- **Texto secundario / bordes**: `#64748B` / `#E2E8F0`

Estados:

- **Success**: `#16A34A`
- **Warning**: `#F59E0B`
- **Error**: `#DC2626`

## Paleta (modo oscuro, negro profundo)

- **Primary**: `#60A5FA`
- **Secondary**: `#B3B3B3`
- **Accent (acciones)**: `#60A5FA`
- **Background**: `#000000`
- **Card**: `#050505`
- **Texto principal**: `#F5F5F5`
- **Texto secundario / bordes**: `#D1D5DB` / `#1A1A1A`

Estados:

- **Success**: `#4ADE80`
- **Warning**: `#FBBF24`
- **Error**: `#F87171`

## Uso recomendado

- Reservar el **accent** para botones primarios, links y foco activo.
- Usar `secondary` para iconografía o etiquetas de soporte.
- Mantener superficies (`background`, `card`) neutras para facilitar lectura de formularios y tablas.
