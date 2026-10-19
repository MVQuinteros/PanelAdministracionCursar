# CURSAR · Panel de administración

[![Deploy](https://github.com/MVQuinteros/PanelAdministracionCursar/actions/workflows/deploy.yml/badge.svg)](https://github.com/MVQuinteros/PanelAdministracionCursar/actions/workflows/deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

Panel web para el equipo de CURSAR: desde acá se administra **todo lo que ve el
usuario en la app móvil** —usuarios y roles, ofertas, instituciones, tags, avisos,
reportes de soporte y resultados del test vocacional— sin tocar la consola de
Firebase.

Sitio en línea: **https://mvquinteros.github.io/PanelAdministracionCursar/**

> El panel no crea cuentas de usuario ni contraseñas: eso lo hace la app móvil
> CURSAR. Acá se entra con una cuenta que ya tenga `rol: 'admin'` y se cambia el
> contenido. Comparte el mismo proyecto de Firebase que la app, así que lo que se
> publica aparece al instante del otro lado.

## ¿Qué hace?

Al iniciar sesión, el administrador entra a un **dashboard** con seis tarjetas de
resumen (usuarios, ofertas, instituciones, test vocacional, avisos y soporte sin
resolver) y cuatro gráficos: ofertas por área, aprobadas contra pendientes,
usuarios por localidad y áreas del test vocacional. Desde el menú lateral accede a
nueve módulos:

- **Dashboard** — el resumen general recién descrito. Las tarjetas llevan al
  módulo correspondiente con un click.
- **Usuarios** — las cuentas de la app: datos de contacto, localidad, rol y último
  acceso. Se pueden editar y borrar, y filtrar por localidad, rol o fecha de alta.
- **Administradores** — quién puede entrar al panel. Se le da acceso a cualquier
  usuario de la app con un click y se le puede quitar después, siempre con dos
  bloqueos de seguridad: no podés quitarte el acceso a vos mismo y no se puede
  dejar al panel sin ningún administrador. Cada cambio queda auditado (quién lo
  hizo y cuándo), y los que perdieron el acceso quedan listados como *ex
  administradores*.
- **Ofertas** — las carreras que se muestran en la app. Se aprueban o rechazan
  con un botón (mientras están pendientes no se publican), se editan, se crean y
  se borran, con búsqueda y filtros por institución, área, nivel, modalidad y
  fecha.
- **Instituciones** — universidades, terciarios y centros de formación. Se
  registran con sus datos de contacto, dirección, coordenadas para el mapa y logo.
- **Tags** — las etiquetas con las que se categorizan las ofertas.
- **Avisos** — las noticias y novedades que aparecen en el inicio de la app.
- **Soporte** — los reportes que envían los usuarios desde la app. Se responden
  desde acá: la respuesta le queda en la app como notificación personal y, si
  querés, se manda también por mail con el botón "Enviar por mail".
- **Test vocacional** — los resultados del test orientativo, con el usuario que lo
  completó, las áreas que le dieron, las ofertas recomendadas y la fecha.

Todos los módulos comparten la misma tabla: buscador, filtros, exportación a CSV
de lo que estás viendo y una columna de acciones por fila.

Además:

- **Modo claro / oscuro** que se recuerda entre sesiones.
- **Diseño responsive**: la misma tabla se adapta a pantallas chicas achicando sus
  columnas, así los botones de acciones nunca quedan fuera de la vista.
- **Registro de administradores deshabilitado** en el login
  (`AppConfig.permitirRegistro = false`): en un panel publicado no puede existir
  un botón que le dé rol `admin` a cualquiera que lo abra.

## Tecnologías

- **Flutter (web)** — panel compilado desde un solo código, sin HTML ni JS a mano.
- **Firebase** — Authentication (login) y Cloud Firestore (base de datos y
  Storage para los logos de las instituciones).
- **Riverpod** para el estado, **go_router** para las rutas y **fl_chart** para
  los gráficos del dashboard.
- **GitHub Pages** para el hospedaje: cada push a `main` analiza, testea, compila
  y publica solo, vía GitHub Actions.

## Ejecutar localmente

```bash
flutter pub get
flutter run -d chrome
```

Los tests y el análisis estático corren antes de cada deploy, pero podés
adelantarlos:

```bash
flutter analyze
flutter test
```

Para publicar a mano (normalmente no hace falta, lo hace el workflow):

```bash
flutter build web --release --base-href /PanelAdministracionCursar/
```

El `--base-href` tiene que respetar las mayúsculas del nombre del repositorio: es
la ruta desde donde se sirve el sitio en Pages, y con otro texto el navegador
pide `main.dart.js` en el lugar equivocado.

## Configuración

El proyecto usa el Firebase configurado en `lib/firebase_options.dart`, el mismo
proyecto que la app móvil. Esos valores no son secretos: la seguridad depende de
las **reglas de Firestore**, no de ocultarlos.

Las reglas viven en el repositorio `AdminCursar` (`firestore.rules`) y son las
mismas para la app y el panel. Los administradores tienen permiso total sobre las
colecciones del panel; los usuarios comunes solo sobre lo suyo.
