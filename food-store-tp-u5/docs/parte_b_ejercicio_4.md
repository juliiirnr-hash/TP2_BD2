# Parte B · Ejercicio 4 — Sensibilidad del archivo de log
## Food Store · `food_store_test` · 2026-10-15

Sí, el propio archivo de log es en sí mismo un activo sensible, porque concentra usuarios, IPs, marcas de tiempo y sentencias SQL completas con datos personales y comerciales en texto plano, además de intentos de acceso fallidos aprovechables por un atacante. Solo deberían poder leerlo los administradores del motor (`postgres`/`admin_datos`), a nivel de sistema operativo como archivo propiedad de `postgres` con modo `0640` —valor ya verificado por defecto— y sin ningún permiso a nivel de motor para los roles de aplicación, soporte o reportes. Además, los logs deben quedar fuera del repositorio git, con rotación y retención definidas, y revisarse únicamente sobre la copia de pruebas.
