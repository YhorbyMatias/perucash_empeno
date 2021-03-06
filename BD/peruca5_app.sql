-- phpMyAdmin SQL Dump
-- version 4.7.3
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 22-09-2017 a las 20:11:49
-- Versión del servidor: 5.6.37
-- Versión de PHP: 5.6.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `peruca5_app`
--
CREATE DATABASE IF NOT EXISTS `peruca5_app` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `peruca5_app`;

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `actualizarDatosCliente` (IN `apel` VARCHAR(100), IN `nomb` VARCHAR(100), IN `ddni` VARCHAR(8), IN `direc` VARCHAR(100), IN `corr` VARCHAR(100), IN `celu` VARCHAR(100), IN `idCli` INT)  NO SQL
begin 
UPDATE `Cliente` SET 
`cliApellidos`=apel,
`cliNombres`=nomb,
`cliDni`=ddni,
`cliDireccion`=direc,
`cliCorreo`=corr,
`cliCelular`=celu
where `idCliente`= idCli;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `coincidePass` (IN `texto` VARCHAR(200), IN `idUser` INT)  NO SQL
SELECT CASE md5(texto) WHEN usuPass THEN 1
 ELSE 0 END as result
 from usuario
 where idUsuario = idUser$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `contarNoFinalizados` (IN `idSuc` INT)  NO SQL
SELECT count(idproducto) as Num
FROM `producto` p 
where prodactivo = 1 and datediff( now(), prodfechainicial )<=30
and idSucursal =idSuc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `contarVencidos` (IN `idSuc` INT)  NO SQL
SELECT count(idproducto) as Num
FROM `producto` p 
where prodactivo = 1 and datediff( now(), prodfechainicial )>30
and idSucursal =idSuc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `datosBasicosUsuario` (IN `idUser` INT)  NO SQL
SELECT u.idUsuario, usunombres, usuapellido, usupoder, u.idsucursal, sucnombre
FROM usuario u inner join sucursal s on u.idSucursal=s.idSucursal
where u.idusuario=idUser and u.usuactivo=1$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `encontrarCliente` (IN `dni` VARCHAR(8))  NO SQL
SELECT * FROM `Cliente` WHERE clidni = dni$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `ingresarDineroEntrada` (IN `valor` FLOAT, IN `motivo` TEXT, IN `idUser` INT, IN `idSuc` INT)  NO SQL
begin
INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idSucursal`) VALUES
(null,0,6,now(),valor, motivo,1, idUser, idSuc);

set @caja=last_insert_id();
select @caja;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `ingresarDineroSalida` (IN `valor` FLOAT, IN `motivo` TEXT, IN `idUser` INT, IN `idSuc` INT)  NO SQL
begin INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idSucursal`) VALUES (null,0,5,now(),valor, motivo,1, idUser, idSuc); set @caja=last_insert_id(); select @caja; end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `ingresarPagoaCuenta` (IN `idPro` INT, IN `montoIn` FLOAT, IN `interesIn` FLOAT, IN `adelanto` FLOAT, IN `idUser` INT)  NO SQL
INSERT INTO `PagoaCuenta`(`idPago`, `idProducto`, `pagMontoInicial`, `pagInteresInicial`, `pagFechaRegistro`, `pagAdelanto`, `idUsuario`)
VALUES (null,idPro,montoIn,interesIn,now(),adelanto,idUser)$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarAdelantoAProducto` (IN `idProd` INT, IN `nuevoAdelanto` FLOAT, IN `idUser` VARCHAR(200))  NO SQL
begin
UPDATE `producto` SET 
`prodObservaciones` =concat('Se adelantó S/. ',round(nuevoAdelanto,2),' de S/. ' , round(`prodMontoEntregado`,2), ' el día ', DATE_FORMAT(now(), "%d/%m/%Y"), '<br>', `prodObservaciones`),
`prodFechaInicial`=now(),
`prodMontoEntregado`=`prodMontoEntregado`-nuevoAdelanto,
`prodAdelanto`=`prodAdelanto` +nuevoAdelanto

WHERE 
`idProducto`= idProd;


INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idProd,2,nuevoAdelanto,now(),idUser,
    '',4,'Todavía sin aprobación');

end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarAmortizacionTodo` (IN `idDesemb` INT, IN `monotoInicial` FLOAT, IN `montoInteres` FLOAT, IN `montoPago` FLOAT, IN `idUser` INT, IN `idProd` INT, IN `usuario` TEXT, IN `idSuc` INT)  NO SQL
BEGIN
INSERT INTO `PagoaCuenta`(`idPago`, `idDesembolso`, `pagMonto`, `pagInteres`, `pagCantidadPagada`, `pagDebeInteres`, `pagFechaRegistro`, `idUsuario`, `idTipoPago`)
VALUES (null,idDesemb,monotoInicial,montoInteres,montoPago,0,now(),idUser,10);

set @pago=last_insert_id();

INSERT INTO `PagoaCuenta`(`idPago`, `idDesembolso`, `pagMonto`, `pagInteres`, `pagCantidadPagada`, `pagDebeInteres`, `pagFechaRegistro`, `idUsuario`, `idTipoPago`)
VALUES (null,idDesemb,monotoInicial,montoInteres,montoPago,0,now(),idUser,13);


INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES (null,idProd,13,now(),montoPago,'',1,usuario,0,idSuc);

INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idProd,9,
     montoPago,now(),usuario,
    '',4,'Todavía sin aprobación');

UPDATE `producto` SET 
`prodFechaInicial`=now(),
`prodUltimaFechaInteres`= DATE_FORMAT(now(), "%d/%m/%Y"),
`prodActivo`=0
WHERE 
`idProducto` = idProd;

UPDATE `prestamo`
SET 
`presActivo`=0,`preIdEstado`=11
WHERE `idProducto`=idProd;

select @pago;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarCompraNew` (IN `cliNomb` VARCHAR(50), IN `cliApelli` VARCHAR(50), IN `cliDirec` VARCHAR(200), IN `dni` VARCHAR(50), IN `email` VARCHAR(50), IN `celular` VARCHAR(50), IN `nomProd` VARCHAR(200), IN `montoentregado` FLOAT, IN `fechainicial` DATE, IN `observaciones` TEXT, IN `usuario` INT, IN `idSuc` INT, IN `fechaRegistro` TEXT)  BEGIN
INSERT INTO `peruca5_app`.`Cliente`
(`idCliente`,
`cliApellidos`,
`cliNombres`,
`cliDni`,
`cliDireccion`,
`cliCorreo`,
`cliCelular`)
VALUES
(null,
lower(trim(cliApelli)), lower(trim(cliNomb)),
dni,
lower(cliDirec),
email,
celular);

set @id=last_insert_id();

INSERT INTO `producto`(`idProducto`, `prodNombre`, `prodMontoEntregado`, `prodInteres`, `prodFechaInicial`, `prodFechaVencimiento`, `prodObservaciones`, `prodMontoPagar`, `idCliente`, `prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal`, `esCompra`)
VALUES
(null,
lower(trim(nomProd)),
montoentregado,0,
fechainicial,'',
observaciones,0,
@id,
1, fechaRegistro, usuario, idSuc,1);

set @comp=last_insert_id();

INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES (null,@id,3,now(),montoentregado,
'',1,usuario,0,idSuc);

select @comp;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarCompraSolo` (IN `nomProd` VARCHAR(200), IN `montoentregado` FLOAT, IN `fechainicial` DATE, IN `observaciones` TEXT, IN `usuario` INT, IN `idCl` INT, IN `idSuc` INT, IN `fechaRegistro` TEXT)  NO SQL
BEGIN
INSERT INTO `producto`(`idProducto`, `prodNombre`, `prodMontoEntregado`, `prodInteres`, `prodFechaInicial`, `prodFechaVencimiento`, `prodObservaciones`, `prodMontoPagar`, `idCliente`, `prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal`, `esCompra`)
VALUES
(null,
lower(trim(nomProd)),
montoentregado, 0,
fechainicial,'',
observaciones,0,
idCl,
1, fechaRegistro, usuario, idSuc, 1);

set @compr=last_insert_id();
select @compr;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarInteresAdelanto` (IN `idDesemb` INT, IN `monotoInicial` FLOAT, IN `montoInteres` FLOAT, IN `montoPago` FLOAT, IN `idUser` INT, IN `idProd` INT, IN `usuario` TEXT, IN `idSuc` INT)  NO SQL
BEGIN
INSERT INTO `PagoaCuenta`(`idPago`, `idDesembolso`, `pagMonto`, `pagInteres`, `pagCantidadPagada`, `pagDebeInteres`, `pagFechaRegistro`, `idUsuario`, `idTipoPago`)
VALUES (null,idDesemb,monotoInicial,montoInteres,montoPago,0,now(),idUser,9);

set @pago=last_insert_id();

INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES (null,idProd,9,now(),montoPago,
'',1,usuario,0,idSuc);

INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idProd,9,
     montoPago,now(),usuario,
    '',4,'Todavía sin aprobación');
    
select @pago;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarProductoNew` (IN `cliNomb` VARCHAR(50), IN `cliApelli` VARCHAR(50), IN `cliDirec` VARCHAR(200), IN `dni` VARCHAR(50), IN `email` VARCHAR(50), IN `celular` VARCHAR(50), IN `nomProd` VARCHAR(200), IN `montoentregado` FLOAT, IN `interes` FLOAT, IN `montopagar` FLOAT, IN `fechainicial` DATE, IN `feachavencimiento` DATE, IN `observaciones` TEXT, IN `usuario` INT, IN `idSuc` INT, IN `fechaRegistro` TEXT)  BEGIN
INSERT INTO `peruca5_app`.`Cliente`
(`idCliente`,
`cliApellidos`,
`cliNombres`,
`cliDni`,
`cliDireccion`,
`cliCorreo`,
`cliCelular`)
VALUES
(null,
lower(trim(cliApelli)), lower(trim(cliNomb)),
dni,
lower(cliDirec),
email,
celular);

set @id=last_insert_id();

INSERT INTO `peruca5_app`.`producto`
(`idProducto`,
`prodNombre`,
`prodMontoEntregado`,
`prodInteres`,
`prodFechaInicial`,
`prodFechaVencimiento`,
`prodObservaciones`,
`prodMontoPagar`,
`idCliente`,
`prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal` )
VALUES
(null,
lower(trim(nomProd)),
montoentregado,
interes,
fechainicial,
feachavencimiento,
observaciones,
montopagar,
@id,
1, fechaRegistro, usuario, idSuc);

set @prod=last_insert_id();

INSERT INTO `prestamo`(`idPrestamo`, `idProducto`, `idCliente`, `preCapital`, `preFechaInicio`, `idSucursal`, `idUsuario`, `presActivo`, `presObservaciones`, `preIdEstado`) VALUES (null,@prod,@id,montoentregado,fechaRegistro,idSuc,usuario,1,'',1);

set @prestamo=last_insert_id();

INSERT INTO `desembolso`(`idDesembolso`, `idPrestamo`, `desCapital`, `desDebeInteres`, `desFechaContarInteres`, `desFechaRegistro`, `desActivo`, `desUsuario`) VALUES (null,@prestamo,montoentregado,0,fechaRegistro,now(),1,usuario);


select @prod;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarProductoSolo` (IN `nomProd` VARCHAR(200), IN `montoentregado` FLOAT, IN `interes` FLOAT, IN `montopagar` FLOAT, IN `fechainicial` DATE, IN `feachavencimiento` DATE, IN `observaciones` TEXT, IN `usuario` INT, IN `idCl` INT, IN `idSuc` INT, IN `fechaRegistro` TEXT)  NO SQL
BEGIN

INSERT INTO `peruca5_app`.`producto`
(`idProducto`,
`prodNombre`,
`prodMontoEntregado`,
`prodInteres`,
`prodFechaInicial`,
`prodFechaVencimiento`,
`prodObservaciones`,
`prodMontoPagar`,
`idCliente`,
`prodActivo`, `prodFechaRegistro`, `IdUsuario`, `idSucursal` )
VALUES
(null,
lower(trim(nomProd)),
montoentregado,
interes,
fechainicial,
feachavencimiento,
observaciones,
montopagar,
idCl,
1, fechaRegistro, usuario, idSuc);

set @prod=last_insert_id();

INSERT INTO `prestamo`(`idPrestamo`, `idProducto`, `idCliente`, `preCapital`, `preFechaInicio`, `idSucursal`, `idUsuario`, `presActivo`, `presObservaciones`, `preIdEstado`) VALUES (null,@prod,idCl,montoentregado,fechaRegistro,idSuc,usuario,1,'',1);

set @prestamo=last_insert_id();

INSERT INTO `desembolso`(`idDesembolso`, `idPrestamo`, `desCapital`, `desDebeInteres`, `desFechaContarInteres`, `desFechaRegistro`, `desActivo`, `desUsuario`) VALUES (null,@prestamo,montoentregado,0,fechaRegistro,now(),1,usuario);

INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES (null,@prod,3,now(),montoentregado,
'',1,usuario,0,idSuc);

select @prod;

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarSucursalNueva` (IN `sucNom` VARCHAR(200), IN `sucLug` VARCHAR(200))  NO SQL
INSERT INTO `sucursal`(`idSucursal`, `sucNombre`, `sucLugar`)
VALUES (null ,sucNom,sucLug)$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `insertarUsuario` (IN `nombre` VARCHAR(50), IN `apellido` VARCHAR(50), IN `nick` VARCHAR(50), IN `pass` VARCHAR(50), IN `poder` INT, IN `idSucur` INT)  NO SQL
INSERT INTO `usuario`(`idUsuario`, `usuNombres`, `usuApellido`,
                      `usuNick`, `usuPass`, `usuPoder`,
                      `idSucursal`, `usuActivo`) 
VALUES (null,apellido,nombre,nick,md5(pass),poder,idSucur,1)$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `inserttempo` (IN `fech` TEXT)  NO SQL
insert into tempo
(idtempo, fecha)
values(null, fech)$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarBuscarNombreProducto` (IN `texto` TEXT)  NO SQL
select idproducto, prodnombre, cliapellidos, clinombres, prodMontoEntregado, prodfecharegistro
from producto p
inner join Cliente c on p.idcliente = c.idCliente
where prodNombre like concat( '%', texto, '%')
order by prodfecharegistro desc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarDesembolsosPorPrestamos` (IN `idDesemb` TEXT)  NO SQL
SELECT d.*, u.usuNick FROM `desembolso` d
inner join usuario u on u.idUsuario=d.desusuario

WHERE FIND_IN_SET( `iddesembolso`, idDesemb)$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarMovimientoFinal` (IN `idProd` INT)  NO SQL
SELECT rp.*, p.prodNombre, dr.repoDescripcion, dr1.repoDescripcion as 'estadoConfirmacion' 
FROM
producto p inner join 
`reportes_producto` rp on p.idProducto= rp.idProducto
inner join DetalleReporte dr on dr.idDetalleReporte= rp.idDetalleReporte
inner join DetalleReporte dr1 on dr1.idDetalleReporte= rp.repoQueConfirma
where rp.idproducto= idProd
order by repofechaocurrencia desc, repoUsuario asc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarMovimientosCajaPorIdProducto` (IN `idProd` INT)  NO SQL
SELECT c.*, u.usuNombres, tipoDescripcion, p.idPrestamo FROM `caja` c
inner join usuario u on u.idUsuario=c.idusuario
inner join tipoProceso tp on tp.idTipoProceso=c.idtipoProceso
inner join prestamo p on c.idproducto=p.idProducto
where c.idProducto=idProd and c.idtipoproceso<>3$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarMovimientosFechaDia` (IN `fecha` TEXT)  NO SQL
SELECT rp.idproducto, p.prodNombre, dr.repoDescripcion, repoUsuario, repoValorMonetario, repoFechaOcurrencia
FROM `reportes_producto` rp
inner join producto p on p.idproducto=rp.idproducto
inner join DetalleReporte dr on dr.idDetalleReporte=rp.iddetallereporte
where DATE_FORMAT(repoFechaOcurrencia,'%Y-%m-%d')= DATE_FORMAT(fecha, '%Y-%m-%d')
order by repoFechaOcurrencia asc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarMovimientosRegistradosFechaDia` (IN `fecha` TEXT)  NO SQL
select idproducto, prodNombre, 'Nuevo crédito' as repoDescripcion, usuNombres, prodMontoEntregado, prodfecharegistro
from producto p inner join usuario u on u.idUsuario=p.idUsuario
where DATE_FORMAT(prodfecharegistro,'%Y-%m-%d')= DATE_FORMAT(fecha, '%Y-%m-%d')$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarMovimientosSinAprobar` (IN `idSuc` INT)  NO SQL
SELECT rp.*, p.prodNombre, dr.repoDescripcion, dr1.repoDescripcion as 'estadoConfirmacion' 
FROM
producto p inner join 
`reportes_producto` rp on p.idProducto= rp.idProducto
inner join DetalleReporte dr on dr.idDetalleReporte= rp.idDetalleReporte
inner join DetalleReporte dr1 on dr1.idDetalleReporte= rp.repoQueConfirma
where repofechaConfirma ='' and p.idSucursal= idSuc
order by repofechaocurrencia desc, repoUsuario asc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarPrestamosPorIdProducto` (IN `idProd` INT)  NO SQL
SELECT `idPrestamo`,`preCapital`,`preFechaInicio`, `preIdEstado`, tp.tipoDescripcion, `repoFechaOcurrencia`, `repoUsuario`
FROM `prestamo` p
inner join tipoProceso tp on p.preIdEstado=tp.idTipoProceso
left join reportes_producto rp on rp.idProducto=p.idproducto
WHERE 
p.idproducto=idProd$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarProductoEspecificoCliente` (IN `idPro` INT)  NO SQL
SELECT * FROM `producto` p
INNER join Cliente c on p.idcliente = c.idcliente
WHERE 
idproducto= idPro
order by prodfechainicial desc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarProductoPorId` (IN `idProd` INT)  NO SQL
BEGIN
select lower( concat(cliApellidos ,', ', cliNombres)) as propietario,
p.`idProducto`, `prodNombre`, 
format( `prodMontoEntregado`,2) as prodMontoEntregado, 
`prodInteres`, `prodFechaInicial`, `prodObservaciones`,
s.sucNombre,  usuNombres as atendio
from producto p
inner join sucursal s on p.idSucursal= s.idSucursal
inner join Cliente c on c.idCliente = p.idCliente
inner join usuario u on u.idUsuario= p.idUsuario
where idProducto = idProd;
END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarProductosPorAprobar` (IN `oficina` INT)  NO SQL
SELECT idProducto, prodNombre,
prodCuantoFinaliza, prodQuienFinaliza, prodFechaFinaliza

FROM `producto`
where prodAprobado=0  and prodActivo=0
and idSucursal=oficina
ORDER BY `producto`.`idProducto`  DESC$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarProductosPorCliente` (IN `idCli` INT)  BEGIN
select p.*, s.sucNombre from producto p
inner join sucursal s on p.idSucursal= s.idSucursal
where idcliente =idCli
order by prodFechaRegistro desc;
END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarProductosVencidos` (IN `idSuc` INT)  NO SQL
SELECT idproducto, prodNombre,
prodMontoEntregado,
concat(cliapellidos, ', ', clinombres) as propietario,
prodFechainicial
FROM `producto` p inner join Cliente c
on c.idcliente = p.idcliente
where prodactivo = 1 and datediff( now(), prodFechainicial )>30
and p.idSucursal = idSuc
order by prodFechainicial asc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarTodoProductosPorSuc` (IN `desde` INT, IN `hasta` INT, IN `idSuc` INT)  NO SQL
begin
SELECT p.idProducto, prodNombre, format( prodMontoEntregado,2) as prodMontoEntregado, 
prodFechaInicial, sucNombre, usuNombres, concat(cliApellidos, ' ', cliNombres) as propietario,
prodActivo
FROM `producto` p inner join usuario u on u.idUsuario = p.idUsuario
inner join sucursal s on s.idSucursal = p.idSucursal
inner join Cliente c on c.idCliente = p.idCliente
where p.idSucursal=idSuc and prodActivo<>0
order by prodFechaInicial asc
limit desde,hasta;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarTodoProductosSinSuc` (IN `desde` INT, IN `hasta` INT)  NO SQL
begin
SELECT p.idProducto, prodNombre, format( prodMontoEntregado,2) as prodMontoEntregado, 
prodFechaInicial, sucNombre, usuNombres,
concat(cliApellidos, ' ', cliNombres) as propietario, prodActivo
FROM `producto` p inner join usuario u on u.idUsuario = p.idUsuario
inner join sucursal s on s.idSucursal = p.idSucursal
inner join Cliente c on c.idCliente = p.idCliente
where prodActivo<>0
order by prodFechaInicial asc
limit desde,hasta;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarTodosProductosEnBDSucursal` (IN `idSuc` INT)  NO SQL
SELECT p.idproducto, prodnombre, prodMontoEntregado, 
DATE_FORMAT(prodFechaRegistro,'%d/%m/%Y') AS prodFechaRegistro,
c.cliApellidos, c.cliNombres, u.usuNick as nick,
case prodActivo when 1 then 'Si' else 'No' end as 'prodActivo'

FROM `producto` p
inner join Cliente c on c.idCliente = p.idcliente
inner join usuario u on u.idUsuario= p.idusuario
where p.idSucursal=idSuc
order by idproducto desc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarTodosProductosNoFinalizados` (IN `idSuc` INT)  NO SQL
SELECT c.*, p.*, u.usuNombres FROM `producto` p
inner join Cliente c
on p.idcliente = c.idcliente
inner join usuario u
on p.idusuario = u.idusuario
where prodactivo =1 and p.idSucursal = idSuc  and datediff( now(), prodFechainicial )<=30
order by prodfechainicial asc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarTodosUsuarios` ()  NO SQL
SELECT u.`idUsuario`, concat( `usuNombres`, ' ',  `usuApellido` ) as nombre, p.`descripcion`,  sucLugar 
FROM `usuario` u inner join sucursal s
on u.`idSucursal`= s.`idSucursal`
inner join poder p on p.idPoder=usuPoder
WHERE `usuActivo`=1
order by usuNombres$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `listarUnUsuario` (IN `idUser` INT)  NO SQL
SELECT u.`idUsuario`, `usuNombres` , `usuApellido`, usuNick,
p.idPoder,  u.idSucursal
FROM `usuario` u inner join sucursal s
on u.`idSucursal`= s.`idSucursal`
inner join poder p on p.idPoder=usuPoder
WHERE idUsuario = idUser
order by usuNombres$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `returnTotalProductos` ()  NO SQL
begin

SELECT COUNT( * ) conteo
FROM  `producto` 
where prodActivo<>0;

end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `returnTotalProductosPorId` (IN `idSuc` INT)  NO SQL
begin

SELECT COUNT( * ) conteo
FROM  `producto` 
where idSucursal = idSuc and prodActivo<>0;

end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `solicitarDatosCompraCliente` (IN `idCompr` INT)  NO SQL
SELECT * FROM `Compras` co
 inner join Cliente c on c.idCliente=co.idCliente
WHERE idcompra =idCompr$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `solicitarProductoPorId` (IN `idProd` INT)  BEGIN
select c.*, p.prodNombre, p.prodObservaciones, prodFechaRegistro, p.idSucursal, s.sucNombre
from Cliente c inner join producto p on c.idcliente = p.idcliente
inner join sucursal s on p.idSucursal= s.idSucursal

where idproducto = idProd ;
END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `temporalCASE` ()  NO SQL
begin 
DECLARE v INT DEFAULT 1;

    CASE v
      WHEN 2 THEN SELECT v;
      WHEN 3 THEN SELECT 0;
      ELSE
        select 'uno';
    END CASE;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `ubicarPersonaProductos` (IN `campo` TEXT)  BEGIN
select `idCliente`, lower(`cliApellidos`) as cliApellidos, lower(`cliNombres`) as cliNombres, `cliDni`, lower(`cliDireccion`) as cliDireccion, `cliCorreo`, `cliCelular`
from Cliente c 
where concat(lower(cliApellidos), ' ', lower(cliNombres)) like concat('%', campo, '%')
or clidni = campo
order by cliApellidos
;
END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateFinalizarEstado` (IN `idPro` INT, IN `usuar` VARCHAR(200), IN `monto` FLOAT)  NO SQL
BEGIN
UPDATE `producto` SET `prodActivo`=0,
`prodCuantoFinaliza`=monto,
`prodQuienFinaliza`=usuar,
`prodFechaFinaliza`=now()
WHERE 
`idProducto` = idPro;


INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idPro,3,monto,now(),usuar,
    '',4,'Todavía sin aprobación');

END$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateFinalizarInteres` (IN `idPro` INT, IN `monto` FLOAT, IN `idUser` VARCHAR(200))  NO SQL
begin 
UPDATE `producto` SET 
`prodFechaInicial`=now(),
`prodObservaciones` =concat('Se canceló el interés S/. ',round(monto,2),' de el día ', DATE_FORMAT(now(), "%d/%m/%Y"), '<br>', `prodObservaciones`),
`prodUltimaFechaInteres`= DATE_FORMAT(now(), "%d/%m/%Y")
WHERE 
`idProducto` = idPro;


INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idPro,1,
     monto,now(),idUser,
    '',4,'Todavía sin aprobación');

end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateFinalizarPrestamo` (IN `idPro` INT, IN `monto` FLOAT, IN `idUser` VARCHAR(200), IN `valorizado` FLOAT, IN `idSuc` INT, IN `usuario` VARCHAR(200), IN `paga` FLOAT)  NO SQL
begin 
UPDATE `producto` SET 
`prodFechaInicial`=now(),
`prodUltimaFechaInteres`= DATE_FORMAT(now(), "%d/%m/%Y"),
`prodActivo`=0
WHERE 
`idProducto` = idPro;

UPDATE `prestamo`
SET 
`presActivo`=0,`preIdEstado`=11
WHERE `idProducto`=idPro;


INSERT INTO `reportes_producto`(
    `idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`,
`repoUsuarioComentario`, `repoQueConfirma`, `repoQuienConfirma`) VALUES (
     null,idPro,8,
     paga,now(),usuario,
    '',4,'Todavía sin aprobación');

INSERT INTO `caja`(`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES (null,idPro,11,now(),paga,concat('Precio original: S/. ', monto), 1,idUser,0,idSuc);

end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateFinalizarSucursal` (IN `idSuc` INT)  NO SQL
UPDATE `sucursal` SET `sucActivo`=0 WHERE idSucursal =idSuc$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateMovimientoAceptar` (IN `idRepo` INT, IN `nomUser` VARCHAR(200))  NO SQL
UPDATE `reportes_producto` SET 
`repoFechaConfirma`=now(),
`repoQueConfirma`=7,
`repoQuienConfirma`=nomUser
WHERE `idReporte`=idRepo$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateMovimientoRematar` (IN `idRepo` INT, IN `nomUser` VARCHAR(200))  NO SQL
UPDATE `reportes_producto` SET 
`repoFechaConfirma`=now(),
`repoQueConfirma`=6,
`repoQuienConfirma`=nomUser
WHERE `idReporte`=idRepo$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateMovimientoRetirar` (IN `idRepo` INT, IN `nomUser` VARCHAR(200))  NO SQL
UPDATE `reportes_producto` SET 
`repoFechaConfirma`=now(),
`repoQueConfirma`=5,
`repoQuienConfirma`=nomUser
WHERE `idReporte`=idRepo$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updatePassSinDatos` (IN `texto` VARCHAR(200), IN `idUser` INT)  NO SQL
begin
UPDATE `usuario` SET
`usuPass` = md5(texto)
WHERE `idUsuario`=idUser;

select 1;
end$$

CREATE DEFINER=`peruca5`@`localhost` PROCEDURE `updateUserDatosConPass` (IN `nombre` VARCHAR(200), IN `apellido` VARCHAR(200), IN `nick` VARCHAR(200), IN `pass` VARCHAR(200), IN `poder` INT, IN `sucursal` INT, IN `idUser` INT)  NO SQL
UPDATE `usuario` SET 
`usuNombres`=nombre,
`usuApellido`=apellido,
`usuNick`=nick,
`usuPass`=md5(pass),
`usuPoder`=poder,
`idSucursal`=sucursal
WHERE `idUsuario`=idUser$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja`
--

CREATE TABLE `caja` (
  `idCaja` int(11) NOT NULL,
  `idProducto` int(11) NOT NULL COMMENT 'mandar 0 si no hay producto',
  `idTipoProceso` int(11) NOT NULL,
  `cajaFecha` datetime NOT NULL,
  `cajaValor` float NOT NULL,
  `cajaObservacion` text NOT NULL,
  `cajaActivo` bit(1) NOT NULL,
  `idUsuario` int(11) NOT NULL,
  `idAprueba` int(11) NOT NULL,
  `idSucursal` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `caja`
--

INSERT INTO `caja` (`idCaja`, `idProducto`, `idTipoProceso`, `cajaFecha`, `cajaValor`, `cajaObservacion`, `cajaActivo`, `idUsuario`, `idAprueba`, `idSucursal`) VALUES
(1, 64, 11, '2017-09-19 19:24:35', 262, 'Precio original: S/. 140', b'1', 9, 0, 2),
(2, 518, 3, '2017-09-19 19:48:17', 400, '', b'1', 8, 0, 1),
(3, 201, 11, '2017-09-19 20:04:25', 281, 'Precio original: S/. 150', b'1', 8, 0, 1),
(4, 204, 11, '2017-09-19 20:06:15', 375, 'Precio original: S/. 200', b'1', 8, 0, 1),
(5, 260, 11, '2017-09-19 20:06:52', 749, 'Precio original: S/. 400', b'1', 8, 0, 1),
(6, 522, 3, '2017-09-20 16:10:14', 100, '', b'1', 3, 0, 1),
(9, 526, 3, '2017-09-21 17:06:33', 170, '', b'1', 3, 0, 1),
(8, 316, 11, '2017-09-20 17:39:58', 244, 'Precio original: S/. 150', b'1', 9, 0, 2),
(10, 528, 3, '2017-09-21 18:36:36', 250, '', b'1', 3, 0, 1),
(11, 530, 3, '2017-09-22 10:34:49', 50, '', b'1', 3, 0, 1),
(12, 384, 3, '2017-09-22 16:51:05', 300, '', b'1', 3, 0, 1),
(13, 535, 13, '2017-09-22 17:43:54', 66.16, '', b'1', 0, 0, 2),
(14, 537, 3, '2017-09-22 18:42:05', 40, '', b'1', 1, 0, 1),
(15, 537, 11, '2017-09-22 18:42:18', 43.8, 'Precio original: S/. 40', b'1', 1, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Cliente`
--

CREATE TABLE `Cliente` (
  `idCliente` int(11) NOT NULL,
  `cliApellidos` varchar(50) NOT NULL,
  `cliNombres` varchar(50) NOT NULL,
  `cliDni` varchar(8) NOT NULL,
  `cliDireccion` varchar(200) NOT NULL,
  `cliCorreo` varchar(50) NOT NULL,
  `cliCelular` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `Cliente`
--

INSERT INTO `Cliente` (`idCliente`, `cliApellidos`, `cliNombres`, `cliDni`, `cliDireccion`, `cliCorreo`, `cliCelular`) VALUES
(1, 'madrid vargas', 'luis fernando', '48211897', 'jr. san martin #247-huancayo', 'vanslove15@gmail.com', '934958237 '),
(2, 'milagros sarapura', 'sharon jenifer', '46573028', 'calle apata s/n - matahuasi (paradero muruhuay)', 'sharonsahe_10@hotmail.com', '948003747'),
(3, 'najera daza', 'raul alex', '47800688', 'jr. santa rasa 1357 - el tambo', '', '944843829'),
(4, 'quispe berrocal', 'miguel', '48583422', 'av. daniel a. carrion 1337-hyo', 'mqberrocal@gmail.com', '995111142'),
(5, 'ycomedes echevarria', 'carlos', '45920195', 'jr. los bosques #440', 'carlos7lim@gmail.com', '956657898'),
(6, 'yancan canchanya', 'katerin', '44594241', 'jose olaya #1635 jPV', '', '961925224'),
(7, 'sedano sanchez', 'jhonnatan', '47508900', 'av. cordova, jr. progreso (chilca)', 'jlegendarios@gmail.com', '064-432241'),
(8, 'ninanya martel ', 'luigi harold', '71097809', 'jr. pachacutec #310 -  el tambo', 'luigi_sak07@hotmail.com', '939409382'),
(9, 'torres cardenas', 'elizabeth clarisa', '40771830', 'jr. hermilio valdizan', 'eliza-tc2406@hotmail.com', '941996175'),
(10, 'ortiz freyre', 'miguel angel', '19911874', 'jr. moquegua #1360 - el tambo', '', '988223369'),
(11, 'palomino gonzales ', 'milagros stefany', '76420947', 'prog. arequipa #993 - chilca', 'milili-11@hotmail.com', '964097073'),
(12, 'rivera menendez', 'jose miguel', '44370823', 'jr. hipolito unanue s/n', 'jose-123rivera@hotmail.com', '941430582'),
(13, 'hinostroza morales', 'moises', '44146810', 'av. los obreros #714-jPV', 'vithmor-eirl@hotmail.com', '984577740'),
(14, 'ames miranda ', 'cesar franshesco', '47585699', 'jr. 28 de julio #229-chilca', 'famesuncofim@gmail.com', '939797541'),
(15, 'peña palomino ', 'gianfranco', '75381486', 'prol. mariategui #328-el tambo', '75381486@continental.com.pe', '945929282'),
(16, 'castillo gaspar', 'jhover carlos', '73197213', 'jr. lima #2509-yauris', '', '998448261'),
(17, 'soto paredes', 'yomira gianella', '75316856', 'jr. san isidro #125- el tambo', 'solita_27_glo@hotmail.com', '979080363'),
(18, 'perez romero', 'michael', '46512606', 'pasaje 2 de mayo #114-chilca', 'michael910mnuc@hotmail.com', '988625355'),
(19, 'aquino lazo', 'brian marco', '71984964', 'calle los quinuales mz. r lt 03 urb. los jardines de san carlos', '', '991455490'),
(20, 'ricse alvarado', 'maycol jhonathan ', '48407935', 'av. huancavelica #3082- el tambo', 'maycol_jra@hotmail.com', '949487983'),
(21, 'cabrera pozo', 'Lizbeth Ruth', '11111111', 'calle', '', '999999999'),
(22, 'rodriguez quincho ', 'jesus', '1111112', 'calle1', '', '999999998'),
(50, 'chucos calixto', 'arturo luis', '11111139', 'c29', '', '996001136'),
(25, 'hidalgo quiroz', 'pablo joel', '11111115', 'c5', '', '999999997'),
(26, 'cardenas pampas', 'geovana', '11111116', 'c6', '', '999999994'),
(27, 'delgado reyes', 'brihan', '11111117', 'c6', '', '999999993'),
(28, 'ruiz curi', 'brayan', '11111118', 'c7', '', '999999992'),
(29, 'cusipoma inga', 'guillermo', '11111119', 'c7', '', '999999991'),
(30, 'alva loayza ', 'manuel alejandro', '11111110', 'c9', '', '999999999'),
(31, 'suarez calcin', 'brihan', '11111120', 'c10', '', '999999999'),
(32, 'velasque gago', 'elvis', '11111121', 'c11', '', '999999999'),
(33, 'vega lino', 'joel', '11111122', 'c12', '', '999999996'),
(34, 'saenz rashuaman', 'luis', '11111123', 'c13', '', '999999996'),
(35, 'cano cusi', 'noe', '11111124', 'c14', '', '964690195'),
(36, 'paredes jilaja', 'juan carlos', '11111125', 'c15', '', '950761767'),
(37, 'rodriguez tananta', 'laura', '11111126', 'c16', '', '921293394'),
(49, 'calle campian', 'adolfo alejandro', '11111138', 'c28', '', '986773600'),
(39, 'javier aliaga', 'diana carolina', '11111128', 'c18', '', '931033865'),
(40, 'caparachin aguilar', 'eduardo', '11111129', 'c19', '', '972097669'),
(41, 'bravo tarazona', 'nino albertho', '11111130', 'c20', '', '999999996'),
(42, 'mendoza sotomayor', 'miguel enrrique', '11111131', 'c21', '', '999999996'),
(43, 'curimania puente', 'deysi rocio', '11111132', 'c22', '', '950187119'),
(44, 'espinoza oregon', 'marco antonio', '11111133', 'c23', '', '939710370'),
(45, 'cabrera perez  ', 'cristian jossian', '11111134', 'c24', '', '999999996'),
(46, 'palomas parac ', 'flori ', '11111135', 'c25', '', '978586133'),
(47, 'mendoza castro', '  aldhair', '73074117', 'jr. inca ripac mz k lt 5', '', '994774316'),
(48, 'gomez cairo ', 'saledad', '45154227', 'jr. tumi #215- el tambo', '', '990008789'),
(51, 'zuñiga', 'miguel', '11111140', 'c30', '', '999999996'),
(52, 'reyes sauñi', 'lucia', '45798915', 'san martin#193- palian', '', '933080901'),
(53, 'palomino basilio ', 'marco antonio', '45797542', 'prog calixto #697-hyo', '', '950950537'),
(54, 'romero aliaga', 'juro dan', '12345678', 'manzanos 1545', 'dan_11@gmail.com', '245252'),
(55, 'rivera rojas', 'enrique phileas', '46162078', 'pj. los husares #135-el tambo', '', '970575516'),
(56, 'balbin barrera', 'diestefano jj romario', '71695974', 'prol. julio llanos #145 sector 20', '', '955939828'),
(57, 'Anccasi paucar', 'clisman mayer', '72675890', 'av. evitamiento y ferrocarril  #825- el tambo', '', '942643000'),
(58, 'trujillo flores', 'roy edgar', '42272948', 'pj giraldes s/n- palian (parque)', '', '920453873'),
(59, 'gaytan huaynalaya', ' kevin david', '73983699', 'jr. progreso # 345 ', '', '929043438'),
(60, 'santana santivañez', 'rocio Del Pilar', '42445125', 'jr. raul porras barrenechea #173- el tambo', '', '979097036'),
(61, 'Manrique', 'Giordan', '72235379', 'Jr Retamas', 'giordan@gmail.com', '986986403'),
(62, 'perez guinea', 'hilda', '19868845', 'jr. agusto b leguia #1171 -chilca', '', '983658558'),
(63, 'meza janampa', 'gian marco', '76067543', 'nicolas  alcazar lt 20 (col. ramiro)-hyo', '', '975924917'),
(64, 'ilizarbe bendezu', 'moises alejandro', '19823558', 'pje. mariscal caceres # 155- piopata', '', '923293150'),
(65, 'cordova campos', ' Jose Luis', '47362090', 'av. palian #645-hyo', '', '991483443'),
(66, 'paz castellares', 'paul vladimir', '44724568', 'av. huancavelica #153 -hyo', '', '971710120'),
(67, 'calla bruno', 'juan carlos', '41660785', 'jr. alan garcia #241- el tambo', '', '962216786'),
(68, 'egoavil arriola', ' jesus miguel', '43715671', 'av. la esperanza #128- chilca', '', '979730815'),
(69, 'arana peña', 'alberto', '20015135', 'grau #1062- el tambo', '', '964009483'),
(70, 'huaynate meza', 'jhosy joel', '45848360', 'jr. manuel scorza #468- el tambo', '', '938198669'),
(71, 'vila joaquin ', 'eddy margoth', '41073246', 'calle real #1252-hyo', '', '964689057'),
(72, 'cano aliaga', 'linton brayan', '76432131', 'jr. coronel pedro aliaga #326- chupaca', '', '944271671'),
(73, 'cano aliaga', 'linton brayan', '76432131', 'jr. coronel pedro aliaga #326- chupaca', '', '944271671'),
(74, 'cabezas meza', 'maycol ralp', '72569108', 'prolg. tarapaca #551- hyo', '', '961500023'),
(75, 'robles arrieta', 'margarita marivel', '44766389', 'parq. industrial #105- el tambo', '', '958823182'),
(76, 'sanchez casas', 'julio pedro', '20056709', 'calle los jasmines#170- saños el tambo -hyo', '', '999479600'),
(77, 'chupurgo mendizabal', 'jose luis', '43334418', 'jr. tarapaca #334-hyo', '', '988889241'),
(78, 'miliano barrantes', 'cristian pholl', '71221679', 'jr. angaraes #783 con hcvca-hyo', '', '923526741'),
(79, 'muñoz laurente', 'jorge luis', '20026651', 'jr. miguel grau s/n - pilcomayo', '', '942956575'),
(80, 'asto gutarra', 'ida rosalinda', '23648081', 'jr. lima #433 con arequipa-hyo', '', '943507745'),
(81, 'huaman alfonso', 'alfredo carlos', '41703203', 'jr. tupac amaru maz. D Lte. 9- chilca', '', '920443687'),
(82, 'nieto tabra', 'cinthya lisset', '46284919', 'jr. los  claveles #896- hyo', '', '934731827'),
(83, 'alarcon porras', 'luis gilberto', '20121075', 'av. huancavelica #1198-hyo', '', '984840275'),
(84, 'villar perez', 'elias', '01153032', 'jr. 28 de julio #1071-huancan', '', '988230081'),
(85, 'ancieta esteban', 'angel bernardino', '42936723', 'av. los minerales #201- hyo', '', '985039312'),
(86, 'retamozo sanchez', 'kenia laleshca', '73088564', 'jr. lima #2509- la rivera', '', '064-411420'),
(87, 'diaz mendieta', 'juan antonio', '70845274', 'pje. huracio gutierrez #316- el tambo', '', '963656637'),
(88, 'huaman rivas', 'rocio', '04220411', 'jr. los cardos #312- la rivera ', '', '064-413283'),
(89, 'oscanoa marcelo del carrillo', 'rocio betty', '20084708', 'pj. santa rosa #158- san carlos', '', '945588076'),
(90, 'asturimac oscanoa', 'richard manuel', '41523555', 'pj antonio paredes #205', '', '959899344'),
(91, 'londoñe soto', 'gabriela', '45119498', 'pj. virgen de guadalupe #225 el tambo', '', '995593498'),
(92, 'simon villanueva', 'stefany karolay', '72266804', 'giraldes y ferrocarril #573-hyo', '', '920451153'),
(93, 'zapata palomino', 'jose francisco', '80688822', 'jr. federico galvez duran. #193-hyo', '', '953913040'),
(94, 'buendia sulca', 'saul arturo', '42683690', 'pj, la breña #110- el tambo', '', '989893510'),
(95, 'rivera cotera', 'patrick nick miguel', '70417368', 'jv. las retamas #648', '', '935075367'),
(96, 'romero lobo', 'alexis julinho', '72672131', 'san carlos y pj santa lucia ', '', '980861537'),
(97, 'julian daga', 'edward jonathan', '70328352', 'pj los olivos l3 mc - saños chico-el tambo', '', '933391941'),
(98, 'ulloa peralta', 'gino alan', '43294847', 'jr. tarapaca #329, 3er y 4to piso', '', '986968162'),
(99, 'romero serpa', 'felix fernando', '19993916', 'jr. los claveles #637-hyo', '', '984093533'),
(100, 'calderon pucuhuaranga', 'yoshiro fortunato', '47891986', 'jr. Panamá #1557- tambo', '', '960814688'),
(101, 'melgar ibarra', 'luis antonio', '07476973', 'pj. san pedro #608 urb. la molina -el tambo', '', '988852260'),
(102, 'reyes castillo', 'janeth', '41237486', 'jr. arequipa #870 - tarma', '', '956454011'),
(103, 'osco castillo', 'eliovera', '70018821', 'jr. manco capac mz d lt 29 - chilca', '', '926046084'),
(104, 'orihuela iriante', 'yanina rosa', '72406957', 'jr. monte carlos #386- cerrito de la libertad ', '', '974137757'),
(105, 'palomino poma', 'josseph gustavo', '47207309', 'jr. union #321-palian', '', '957811667'),
(106, 'bustamante romero', 'paola', '73072689', 'jr. parra del riego #1963-pio pata', '', '963321038'),
(107, 'galvan Rojas', 'Misael Jonatan', '45490853', 'Av. Universitaria 558 - Ciudad Univ. Saños chico', 'jgalvan.colpaingenieros@gmail.com', '928304291'),
(108, 'artica torres', 'maria gladys', '19838758', 'pj. bernaola #174-chilca', '', '961610103'),
(109, 'martinez alvarado', ' carlos', '70764655', 'jr. puno 348 - tarma', '', '958696353'),
(110, 'clemente avila', 'luis miguel', '42855461', 'pj. chavin 349- el tambo', '', '976082982'),
(111, 'egoavil villegas', 'luis fernando', '72196085', 'jr. micaela bastidas 442- pio pata', '', '943257736'),
(112, 'panduro jumachi', 'edvin', '48068324', 'pj los diamantes con santa rosa s/n', '', '945678437'),
(113, 'acosta santamaria', 'jhon manuel', '76260498', 'san jose de umuto 290 el tambo huancayo', 'jmas_271994@hotmail.com', '941823928'),
(114, 'matos briceño', 'lizzet fiorella', '45535998', 'pje. mariategui #150- tambo', '', '934800030'),
(115, 'quispe toscano', 'erick', '76651918', 'jr. diamante azul 211- el tambo ', '', '988944849'),
(116, 'cifuentes rivera', 'jose francisco', '19997114', 'jr. cuzco 442', '', '960585773'),
(117, 'abasto flor', 'fiorella isabel', '71229398', 'jr. julio c tello 356', '', '931153850'),
(118, 'salazar soto', 'saul alberto', '48644308', 'pje. el sol 191 la florida', '', '950560270'),
(119, 'martinez diaz', 'dhayans esther', '70146068', 'carretera central km 115 san pedro de saños', '', '920060614'),
(120, 'lloclla najarro', 'cristian', '60635736', 'jr. dos de mayo 1528 huancan ', '', '994887061'),
(121, 'romero gonsales', 'jim william', '73955379', 'c h \"la breña\" block c departamento 203- san carlos', '', '978819376'),
(122, 'trinidad marcelo', 'gustavo daniel', '70825125', 'juan chipana s/n san agustín de cajas ', '', '938662017'),
(123, 'anccasi cunya', 'fredy cesar', '23272489', 'av. orion mz n lt4 ', '', '963503384'),
(124, 'gonzales armas', 'vladimir ernesto', '40012029', 'pj. chalco 121 millotingo', '', '966011902'),
(125, 'pisco tovar', 'michael cristian', '41651673', 'jr. cuzco 2110- ', '', '997593801'),
(126, 'matos calderon', 'yosip andy', '45340425', 'jr. ayacucho 130-hyo', '', '928045171'),
(127, 'gene ramos', 'aurelio', '00001234', 'av. real 441', 'mm.s@gg.com', '92536111'),
(128, 'galindo auris', 'ghesvil anhy', '71503114', 'pj nueva esperanza 190 el tambo', '', '940666834'),
(129, 'reyes salvador', 'brigida jackeline', '74623661', 'av. huaytapallana mz e lt 17 urb las retamas de san luis', '', '972888202'),
(130, 'pimentel montero', 'juvencio', '23702786', 'av. circumvalacion  835- cerrito de la libertad ', '', '964003509'),
(131, 'solis quispe', 'daniel royer', '70223885', 'diamante azul 107 - el tambo', '', '943036227'),
(132, 'huaynate mosquera', 'denis dione', '46542706', 'pj arana s/n palian ', '', '949772529'),
(133, 'perea sanchez', 'victor gabriel', '80260242', 'circuito huaytapallana 318-el tambo', '', '960244716'),
(134, 'ortiz huatuco', 'christian nicolas', '45696740', 'jr. cahuide sec. sur s/n jauja', '', '956439341'),
(135, 'valdivia vasquez', 'elias amos', '77377576', 'jr.la marina #795 - el tambo', 'AMOS_VALDIVIA@HOTMAIL.COM', '940651731'),
(136, 'torres cueva', 'susan lizbeth', '70306669', 'ayacucho y moquegua', '', '987245102'),
(137, 'sulla ortiz', 'jorge luis', '41526508', 'prolg. ancash #842- chilca', '', '954932424'),
(138, 'nakasone guzman', 'edgard yoshio', '43396763', 'urb. salazar mz d lt. 23 - el tambo', '', '985900566'),
(139, 'coronel bonifacio', 'jim junir', '12121212', 'manuel alonso 5 piso stan 18', '', '987654321'),
(140, 'melgar ibarra', 'luis antonio', '07476973', 'psj. san pedro 608', '', '988852260'),
(141, 'vidal huaman', 'isaias efer', '70210452', 'av. parra 1150 - pilcomayo', '', '970150570'),
(142, 'zuñiga calderon', 'eduardo daniel bradley', '76903715', 'av. carmen del solar y marte', '', '991288058'),
(143, 'chihuan quispe', 'anthoni', '70242138', 'jr. rancas 231- hyo', '', '954804326'),
(144, 'mallma davila', 'carlos alberto', '42842120', 'jr.delfin levano 549', '', '951388898'),
(145, 'payano camarena', 'gustavo', '43336782', 'av. jose carlos mariategui 2030', '', '967920725'),
(146, 'flores romero', 'cintya pamela', '42172977', 'jr. parra del riego 466', '', '962600720'),
(147, 'camarena leon', 'max alberto', '20089382', 'jr. miguel grau km1.5 carretera centarl margen derecha pilcomayo', '', '963638025'),
(148, 'reyes artica', 'clementina', '23719263', 'pje. los nevados #155-hyo', '', '959711502'),
(149, 'galvez huaira', 'cristian', '48089833', 'jr. sebastian lorente #2022', '', '941697875'),
(150, 'hilario corilla', 'annika gessela', '72393147', 'coperativa santa isabel av. alameda #18', '', '964064727'),
(151, 'ruiz varillas', 'ana cecilia', '46270292', 'jr. santa rosa #414 chilca', '', '993648084'),
(152, 'gonzalez cardenas', 'paulo  cesar igor', '42704198', 'pj los jazmines mz  n blok r4', '', '942463346'),
(153, 'llallico garcia', 'joselo', '47802658', 'jr. tacna #550-el tambo ', '', '933309305'),
(154, 'hurtado surichaqui', 'leonarda jessica', '44518202', 'diamantes azul #268 - cooperativa 1 de mayo ', '', '995999511'),
(155, 'veliz de villa aguirre', 'carlos alberto', '20073613', 'av. los andes 885', '', '954001083'),
(156, 'cardenas pampas', 'giovanna', '20113349', 'las retamas #476- la rivera', '', '980944523'),
(157, 'rojas soto', 'sonia germana', '19870042', 'pje. flemnj 228 gonsales iv etapa- el tambo ', '', '940160575'),
(158, 'bermudez alarcon', 'dolly judith', '41086251', 'pje nuñez 192- chilca', '', '993565835'),
(159, 'huansi vasquez', 'magaly', '77474210', 'pj pinar 157- goyzueta ', '', '996213322'),
(160, 'gonzales lopez', 'liz margot', '20105217', 'jr, humbolt 108 - chilca', 'lizi28@hotmail.com', '997895668'),
(161, 'parimango carhuas', 'julio cesar', '47495352', 'jr. antonio de zela 078 chilca alt de proceres', '', '954917765 - 962511591'),
(162, 'espinoza anquipa', 'freddy', '41166332', 'av alfonso ugarte s/n huancan hyo', '', '938255368'),
(163, 'cano aliaga', 'linton brayan', '76432131', 'jr. coronel pedro aliaga 326', '', '944271671'),
(164, 'zambrano rojas', 'rodolfo jordan', '71809815', 'loreto 1472 -hyo', '', '973236480'),
(165, 'rafael mucha', 'cyndi', '46936121', 'av. la marina # 728', '', '979008012'),
(166, 'almonacid ccoriñaupa', 'christofer jhonatan', '77350211', 'jr.bolognesi 2032', '', '993650352'),
(167, 'garcia chacalcaje', 'julio armando', '24577025', 'conjunto av juan parra del riego blo 1 dep 301 2da etapa (hospital ramiro priale priale)', '', '945299772'),
(168, 'lauro sosa', 'carola natery', '74303580', 'jr. libertad y bolognesi #1314', '', '991559854'),
(169, 'ore meza', 'sharon rouse', '76370927', 'av. palian #925 - hyo', '', '989109120'),
(170, 'papuico carhuamaca', 'vanessa olga', '75276808', 'jr. huancas #319 -hyo', '', '925253740'),
(171, 'paniagua uscata', 'luis miguel', '47247878', 'calle san jose 406-umuto', '', '910887816'),
(172, 'valera nuñez', 'holenka ariadna', '73961279', 'al frende de u continetal', '', '952945226'),
(173, 'ojeda rodriguez', 'erick martin', '72154864', 'jr. moquegua #154', '', '955190037'),
(174, 'flores palian', 'yony', '47660312', 'jr. maria resh #144 palian', '', '934147817'),
(175, 'clemente tueros', 'joseph kevin', '72071968', 'jr mariscal castilla s/n - chilca', '', '956618885'),
(176, 'peñares castro', 'lidia gladys', '44035322', 'calle los  rubies 105- el tambo', '', '961618880'),
(177, 'gonsalves perez', 'catherine kelly', '20114814', 'jr. panama n°745-el tambo', '', '994680646'),
(178, 'llacua rodriguez', 'santiago alejandro', '76248824', 'pje. los jardines #435-el tambo', '', '993656698'),
(179, 'pecho caqui', 'miguel angel', '42507760', 'av. tahantinsuyo 004-el tambo', '', '999765417'),
(180, 'picho peña', 'jesus piter', '76586840', 'psj don bosco 147 - tambo', '', '923380323'),
(181, 'oropeza lazo', 'royer michael', '45976224', 'av huancavelica 1860-hyo', '', '924051359'),
(182, 'bullon garcia', 'jan marco', '70332469', 'jr jose galvez #107', '', '966190430'),
(183, 'castro sedano', 'jhon clis', '76359670', 'av. 2 de mayo s/n chilca ', '', '651785962'),
(184, 'vidal reyes', 'jhon cesar', '40435219', 'jr. pedro galvez 1326 pio pata', '', '964012721'),
(185, 'zavala santana', 'katheryn pamela', '46674544', 'jr. los nevados mz b lt 11', '', '921036990'),
(186, 'tueros lara', 'nadia elizabeth', '46497788', 'av. san carlos cuadra 14 ', '', '959512983'),
(187, 'vergara alfaro', 'joseph stiven', '48189332', 'jr. huari 285 ', '', '064-413377'),
(188, 'cano lazo', 'bruce antonio', '77663378', 'av. hvca 1860', '', '997873064'),
(189, 'martinez diaz', 'dhayans esther', '70146088', 'carretera central 11.5 san pedro de saño', '', '920060614'),
(190, 'nuñez marti', ' jhimy horsson', '45087776', 'jr. 28 de julio 971 - chilca', '', '954788025'),
(191, 'nuñez londoñe', 'kerly jajayra', '77242186', 'jr. virgen de guadalupe 225', '', '972026483'),
(192, 'miranda salome', 'elva yanyna', '44636269', 'av. los incas s/n-quilcas', '', '931910767'),
(193, 'vidal romero', 'fernando', '60382979', 'av. tahuantinsuyo s/n el tambo', '', '970949799'),
(194, 'collachagua leyva', 'jhony alberto', '20042705', 'jr. santos chocano 809-chilca', '', '979486236'),
(195, 'orellana jimenez', 'cristiam ernesto', '76668020', 'jr.arequipa 1808 -el tambo', '', '925027680'),
(196, 'velarde ponce', 'omar enrique', '45064608', 'los acantilados 196 - el tambo', '', '993258428'),
(197, 'sinche cierto', 'beatriz rosario', '72909190', 'jr. lima #177-hyo', '', '924507883'),
(198, 'torres caceres', 'morgoth liliana', '20064910', 'ambrocio salasar mg12 parra del riego', '', '933356258'),
(199, 'nima guerra', 'lizeth elena', '70033207', 'calle junin mz 3lt2 el tambo', '', '976316259'),
(200, 'huamani tornero', 'marco antonio', '45617724', 'jr. pueblo union 307. chilca', '', '938810490'),
(201, 'arancel aparco', 'brandon', '76245848', 'av circunvalacion  559 - 387 ', '', '969390866'),
(202, 'aguirre valero', 'tulio dardo', '42483910', 'jr arequipa 870 - tarma', '', '942901003'),
(203, 'gonzales paucar', 'enrique', '48300990', 'pj aguila- san jeronimo ', '', '941897161'),
(204, 'flores arias', 'javier guzman', '71614857', 'proceres y toledo - chilca ', '', '943953760'),
(205, 'flores huayra', 'conthia miluska', '43433744', 'jr los cosmos 213-hyo', '', '924403627'),
(206, 'grados espiritu', 'luis antonio', '47124282', 'jr callao 862', '', '985022489'),
(207, 'ramos eugenio', 'jean francis eliel', '72620882', 'av. filomena #155-chilca ', '', '940602586'),
(208, 'quispe aguirre', 'juan jose', '20051307', 'av. 13 de noviembre 1081 - el tambo', '', '988196027'),
(209, 'wissar rivas', 'cristhian', '43890942', 'jr. manchego muchos #280-el tambo', '', '936102844'),
(210, 'acevedo farge', 'edith regina', '20115562', 'los gladiolos 132 la rivera ', '', '923475541'),
(211, 'merlo chero', 'javier enrique', '76242802', 'san carlos y san judas 726', '', '984174286'),
(212, 'ñaupari dionicio', 'delmer vladimir', '48425538', 'psj. tacna 128- el tambo', '', '955208443'),
(213, 'carhuallanqui escobar', 'dennis paul', '70415131', 'pj los angeles s/n - huancan', '', '927657856'),
(214, 'camani quispe', 'eduardo', '72098808', 'calle alisos s/n - la rivera', '', '972245901'),
(215, 'vitor cerron', 'katherine yadiara', '70322609', 'av ferrocarril 773 -hyo', '', '939388810'),
(216, 'luchsinger sahahun', 'samuel eduardo', '48830370', 'prolg. abancay 110 int 101 apr 002', '', '980624965-992443551'),
(217, 'uribe carbajal', 'angel nicolas', '42509022', 'jr san carlos 557', 'awc.gest@hotmail.com', '992580583'),
(218, 'vila joaquin', 'eddy margoth', '41073546', 'calle real 1252', 'EDDYMARGOTH.VILA@ferreyros.com.pe', '964689057'),
(219, 'chavez cochachi', 'jennifer paola', '71048867', 'jr. estibina 107c.v. de mayo', 'CHAVEZ.JPCC@HOTMAIL.COM', '943086227'),
(220, 'untiveros palomino', 'fiorela', '76802027', 'jr loreto 850', 'fio.untiveros.14@gmail.com', '930019016'),
(221, 'surichaqui gutierrez', 'lincol', '43531992', 'pje. las montañas # 136 - el tambo', '', '949341103'),
(222, 'portilla rosales', 'marco', '73018284', 'calle pakras 936 hyo', 'marco_10@hotmail.com', '952125544'),
(223, 'chavez curi', 'bryan jesus', '71070612', 'av tahuantinsuyo sn', 'bryan12_jesus5@hotmail.com', '921862356'),
(224, 'angulo cardenas', 'ernesto', '20076463', 'av. huancavelica 1460  - hyo', '', '954138105'),
(225, 'sotelo solis', 'juan javier', '44313047', 'av. taylor 1373', '', '931413717'),
(226, 'odontologa odon', 'odontologia', '98753642', 'odon 123 odon', '', '987652341'),
(227, 'osores davila', 'claudio jacob', '44938701', 'jr tumbes mz a lote 9 _ el tambo ', '', '985983521'),
(228, 'inca ticllacuri', 'wilmer jhon', '47917052', 'av.huacar s/n barrio miraflores', '', '952837644'),
(229, 'panduro jumachi', 'walter', '62272823', 'jr. yaullos s/n pucara', '', '945318194'),
(230, 'monroy quiroz', 'miguel', '46491417', 'calle 1 urb. san antonio', '', '978586077'),
(231, 'morales romero', 'deysi fresia', '76662645', 'jr. pedro galves #1360', '', '920060614'),
(232, 'garces quispe', 'michelle kelly', '76201835', 'jr augusto b leguia 641', 'michellegarces98@gmail.com', '977783224'),
(233, 'espeza de la cruz', 'jaime', '44493863', 'pasaje angulo 127', 'jaime_speza@hotmail.com', '990196740'),
(234, 'iriarte curo', 'flor yessenia', '75166888', 'av. 2 de mayo 480 - chilca', '', '974032653'),
(235, 'jesus miranda', 'ruth izela', '20051479', 'av. fidel miranda 1528-sapallanga', '', '978004258'),
(236, 'suarez torres', 'luis enrique', '71438072', 'jr montani 348', 'suares@hotmail.com', '936260637'),
(237, 'garcia malpartida', 'jeny', '44946120', 'av mariscal castilla 4336', 'jenygm3112@hotmail.com', '964303178'),
(238, 'orellana jimenez', ' cristian Ernesto', '76668020', '-', '-', '925027680'),
(239, 'saenz moy', 'giuseppe francisco', '73093485', 'av. centenario y olaya', '', '937503277'),
(240, 'valera cardenas', 'herman', '19881059', 'av. cayma  608 urb. chavez', '', '944452777 - 974685296'),
(241, 'martinez ojeda', 'cesar luis', '20020053', 'santa isabel 138 - el tambo', '', '964942699'),
(242, 'ludeña hernandez', 'paul antonio', '45384027', 'jr ayacucho 579 - huancayo', 'tonio_18@hotmail.com', '980506639'),
(243, 'cosme ore', 'eliana leslie', '71777185', 'jr. pachacutec s/n saños chico', '', '987498750'),
(244, 'chavez tarazona', 'cesar clodomiro', '46768804', 'prol tujillo 1042 hyo', '', '995564586'),
(245, 'lopez diaz', 'simon enrique', '46034641', 'mz g lt 7 urb ambrosio salazar', '', '937012312'),
(246, 'aroni mansilla', 'yanet', '42184902', 'pje. huaytapallana 294', '', '999536820'),
(247, 'marallano altez', 'ronald timothy', '48509866', 'jr. las casuarinas mz e lt 14 - florida', '', '963056302'),
(248, 'pilares zevallos', 'juan jose', '45394611', 'calle los fresnos n°17 huancayo', '', '923272229'),
(249, 'lavajos milla', 'marco antonio', '40087128', 'a matista 126', '', '969267770'),
(250, 'panduro sinti', 'raul', '46617945', 'pje los diamantes 265-millotingo', '', '938474738'),
(251, 'palpa zevallos', 'enguiel luis', '47069191', 'calle jupiter 131-hyo', '', '938770770'),
(252, 'flores diaz', 'jose', '73971276', 'psje. san lucas 114-jauja', '', '947891115'),
(253, 'laura gomez', 'jose luis', '42074830', '26 de nov', 'amigos_jota@hotmail.com', '997898989'),
(254, 'panduro sinto', 'raul', '45789856', 'huancayo', 'huancayo', 'huancayo'),
(255, 'rivera menendez', 'jose miguel', '78989889', 'jr hipolito hunanue 500 el tambo', 'jose miguel', '979898989'),
(256, 'torre manrique', 'dayana lisseth', '75279957', 'av 9 octubre 350', 'dayana', '987533366'),
(257, 'paucar gabriel', 'lorena maricruz', '70150711', 'jr las retamas y las flores ', 'lorena', '954164747'),
(258, 'sandoval acosta', 'edson ramiro', '19964233', 'pj. sebastian lorente #115-pio pata', '', '964745226'),
(259, 'gamarra rivera', 'patricia elizabeth', '42176611', 'pj. 5 de agosto s/n - pio pata', '', '991087853'),
(260, 'machacuay chuco', 'liz jazmin', '70916286', 'ciudad universitaria ', '', '960088098'),
(261, 'flores chocca', 'willian', '42544934', 'jr. los bosques 689- el tambo', '', '987553013'),
(262, 'pomacarhua victorio', 'yasmin estefani', '48298618', 'pedro galves con huancavelica 926', '', '927687846'),
(263, 'garcia shanki', 'elvis luis', '44524300', 'jr. cuzco 531-hyo', '', '931742829'),
(264, 'chocca crispin', 'nilo jersy', '47238282', 'nicolas de pierola 301 chilca', '', '937142527'),
(265, 'hilario ladera', 'gumercindo nicolas', '10603484', 'pj abel martinez 381 - chilca', '', '951192596'),
(266, 'torrejon limpias', 'ronald josue', '7761511', 'jr. puno - hyo', '', '990633224'),
(267, 'huaire aranda', 'abel bacilio', '21260994', 'pj jesus maria 351- el tambo', '', '991838715'),
(268, 'rojas camasca', 'lito', '43645132', 'psje diego ferrer 170 san isidro', 'lito_rojas@hotmail.com', '975009299'),
(269, 'derenzin solari', 'victoria yazminc', '70092609', 'manchego quiñones 161', '', '994350978'),
(270, 'moron cifuentes', 'lorenzo', '19863528', 'pj santa sofia 195', '', '959262111'),
(271, 'perez lazo', 'samuel', '48326491', 'pj. blanca ahuray s7n huancan', '', '975291888'),
(272, 'villanueva osorio', 'brayan guillermo', '72373729', 'manzanos y arequipa 659 - el tambo', '', '939572410'),
(273, 'lolo roberto', 'shirly jasmin', '60391721', 'dos de mayo ', '', '924161593'),
(274, 'ramos quincho', 'bety caty', '42241682', 'jr. las retamas y pje trebol 499', '', '925462286'),
(275, 'adauto crisostomo', 'mery mercedes', '20115978', 'jv. circumvalacion 419-el tambo', '', '964002021'),
(276, 'leiva diaz', 'jhonny anthony', '48556676', 'av. daniel alcides carrion 2330-hyo', '', '964825802'),
(277, 'perez maldonado', 'kevin mijael', '45334613', 'jr. antonio lobato 1229-el tambo', '', '939477700'),
(278, 'chileno romero', 'cristian clemente', '70812800', 'jr loreto 1951- hyo', '', '923827735'),
(279, 'estrada espinal', 'bruno edu', '77477284', 'pj san santiago 205-san carlos', '', '975934343'),
(280, 'terreros galarza', 'javier jimmy', '70399195', 'psj.umuto 328 sector 07 -. el tambo', '', '966099302'),
(281, 'huancauqui rojas', 'rolan russe', '47430162', 'av. leopoldo peña s/n ', '', '987659611'),
(282, 'sandoval peña', 'aracely susy', '71668277', 'prrol. tarapaca 109-hyo', '', '941429070'),
(283, 'luque monago', 'armando efrain', '09697669', 'av arequipa s/n ex reniec', '', '963723176'),
(284, 'perez bustamante', 'silvana mariela', '20054648', 'psj. porvenir - el tambo', '', '936407425'),
(285, 'leon cerron', 'erick richarr', '71700318', 'jr. iquitos 248-concepción ', '', '927995946'),
(286, 'huaypar quispe', 'patricia', '48412312', 'pj. ignacio baldeon 135', '', '933916863'),
(287, 'huaypar quispe', 'patricia', '48412312', 'pj. ignacio baldeon 135', '', '933916863'),
(288, 'dolorier alvarez', 'yeffry felix', '42299246', 'pj mercedes cabello 160', '', '975869689'),
(289, 'avellaneda ramos', 'hoana', '45352759', 'jr. lima 449 -hyo', '', '964282370'),
(290, 'orihuela perez', 'jordan daniel', '75416184', 'pj porvenir 202', '', '979920501'),
(291, 'vivas melgar', 'monica angela', '48610296', 'jr. galcilazo de la vega 262 el tambo', '', '944442901'),
(292, 'rojas basilo', 'dither rafael', '44043666', 'jr. husares de junin 760', '', '971711346'),
(293, 'buendia urbina', 'juan jose', '41287116', 'pj. los alamos 130-el tambo', '', '964004099'),
(294, 'torres sovero', 'luz maribel', '40739487', 'calle las begonias 091-el tambo', '', '933239824'),
(295, 'herrera aguilar', 'betty paola', '41166299', 'calle los heroes 348-sicaya', '', '999518066'),
(296, 'matos koo', 'catherine', '46487677', 'av. huancavelica #599', '', '988488885'),
(297, 'valentin huanuco', 'alioshka eduardo', '41608750', 'jr oswaldo barreto 1041 - el tambo', '', '955655053'),
(298, 'cornejo vidal', 'jotam reynaldo', '73739650', 'jr. cuzco 1962 la ribera', '', '923700607'),
(299, 'perez pinedo', 'pedro paul', '45264701', 'jr. los gladiolos 197', '', '950662910'),
(300, 'guerrero meza', 'liz vanessa', '75802152', 'real 551- el tambo', '', '998653785'),
(301, 'romero paucar', 'jose luis', '42412923', 'pj 17 de setiembre mz p block 14', '', '989477942'),
(302, 'soto bruno', 'cristhian roler', '44826974', 'jr. alan garcia 240 el tambo', '', '927467220'),
(303, 'rojas diaz', 'lincoln raul', '20115487', 'av. centenario #965 - hyo', '', '987540553'),
(304, 'yauli orozco', 'anali', '45128595', 'jr las retamas 557', 'anali@hotmail.com', '975869689'),
(305, 'huaman chavez', 'julian emilio', '72216511', 'jr. los manzanos 1175 el tambo', '', '943787137'),
(306, 'bendezu eulogio', 'jesus millagui', '72696602', 'jr. progreso 1203 el tambo', '', '967599562'),
(307, 'bazan rojas', 'eludio', '77680205', 'prol. atalaya 2556 el tambo', '', '954716526'),
(308, 'estrella pianto', 'daryl stefanie', '47235131', 'jr. miguel grau 1310 pilcomayo', '', '964320932'),
(309, 'paredes peinado', 'jhonatan joel', '73601170', 'jr. trujillo 889 - el tambo', '', '930475923'),
(310, 'avila uceda', 'hansel daniel', '73600004', '28 de julio 587 chilca', '', '964744288'),
(311, 'bendezu esteban', 'catherine vanesa', '77282601', 'jr hipolito unanue 297', '', '963344138'),
(312, 'perez torres', 'jorge luis', '72449774', 'av 13 de noviembre 306', '', '985555503'),
(313, 'garcia canales', 'ana isabel', '19851069', 'jr. libertad 441 el tambo', '', '964444485'),
(314, 'povis damian', 'miguel angel', '70294199', 'calle venecia mz c lt 15', '', '964710711'),
(315, 'ticse aranda', 'luis carlos', '43577829', 'av. leoncio prado 107', '', '956762326'),
(316, 'duran contreras', 'luis angel', '46855876', 'av. la esperanza 773 el tambo', '', '954976041'),
(317, 'mucha rivera', 'diego', '47051288', 'psje san fernando 251', 'forever_ciatisesa@hotmail.com', '982444406'),
(318, 'rivera paitan', 'gladis teresa', '41372707', 'jr antonio razuri 115-piopata', '', '947558755'),
(319, 'sotomayor chirinos', 'raul', '29636784', 'calle real plaza vea', 'rkhanac@gmail.com', '960926759'),
(320, 'auqui benito', 'alejandro', '42992326', 'psje francisco de zela 259', 'abauqui@hotmail.com', '964143264'),
(321, 'arroyo flores', 'carlos daniel', '72743978', 'psje marticorena 111', 'carlosdx21@hotmail.com', '937597396'),
(322, 'canales puente', 'luis fernando', '47580115', 'jorge chaves pilcomayo sta rosa', 'luis_16_500@hotmail.com', '945513123'),
(323, 'aguirre sulca', 'laime', '72785249', 'gonzales prada 636', 'luchoar_2@hotmail.com', '939032393'),
(324, 'cordova torres', 'miriam', '19870743', 'jr las violetas mzd lt15', 'miriam@hotmail.com', '965047013'),
(325, 'gamboa cardenas', 'jimmy arthur', '77080979', 'ica antigua 1420', 'gamboa_cardenasj@gmail.com', '931247646'),
(326, 'palacios meza', 'jeunisse merylin', '45426800', 'prol. san antonio 112 - san carlos', '', '976129898'),
(327, 'huaypar quispe', 'patricia', '48412322', 'pj. ignacio baldeon 135', '', '933716863'),
(328, 'aroni mansilla', 'magno', '40250634', 'jr. huaytapallana 294', '', '995566887'),
(329, 'bravo lozano', 'jose antonio', '42105676', 'jr. moquegua 485 - hyo', '', '932036194'),
(330, 'pariona', 'carlos', '99998888', '', '', ''),
(331, 'de la cruz', 'fiorella', '43163395', 'av. 13 de noviembre #1148', '', '990867971'),
(332, 'quilca gabriel', 'romulo florencio', '43748307', 'jr. san juda tadeo #1320', '', '936577638'),
(333, 'espinoza grados', ' augusto cesar', '41648919', 'jr revolucion 200 - pilcomayo', 'ousugaraser@hotmail.com', '994637555'),
(334, 'carhuallanqui alvarez', 'teodoro', '60584574', 'av. heroes de la breña #303', '', '982953378'),
(335, 'anchiraico olivares', 'dennis enrique', '41410740', 'urb. ambrosio salazar g-2', '', '989226802'),
(336, 'yudy del pilar estrada silvia/sacramento estrada', 'juan diego', '73901668', 'macchupuchu 221 -el tambo', '', '931930679'),
(337, 'cordova torres', 'phill', '78018886', 'av.palian 839', 'elbimt879@hotmail.com', '962218183'),
(338, 'acuña peñaloza', 'alejandro', '43640603', 'cooperativa santa isabel mz r l 5 ', '', '972593550'),
(339, 'poma cayllahua', 'denis', '43597679', 'pj grau 106-hyo', '', '995559738'),
(340, 'millan camposano', 'hector vicehich', '20051577', 'jr. panama 1707 el tambo', '', '929283262'),
(341, 'salvatierra', 'caincela', '73737373', 'calle', '', '922442106'),
(342, 'hinostrosa rosales', 'jheymy', '78787887', 'calle1', '', '952358129'),
(343, 'vila tinoco', 'marco antonio', '48578986', 'jr las brisas', 'marc_27_148@hotmail.com', '964550659'),
(344, 'escobar huanay', 'jhordan', '89452378', 'calle3', '', '971000173'),
(345, 'lifonso mercado', 'yordan ancelmo', '69587412', 'calle 3', '', '997886272'),
(346, 'jhanpool raul', 'calderon cordova', '85962374', 'calle4', '', '930171567'),
(347, 'sin nombre', 'anonimo', '10101010', 'calle5', '', '99999998'),
(348, 'prueba', 'prueba', '00001111', '', '', ''),
(349, 'llantoy  paucar', 'anyelo', '48343200', 'jr las brisas', 'ANYELO@HOTMAIL.COM', '932390675'),
(350, 'marcos fabian', 'alfredo wilder', '20054219', 'pj. saul muños menacho 135', '', '939789603'),
(351, 'marcelo marcelo', 'erick javier', '47118310', 'jr. amazonas (parq 15 de junio)', '', '928956007'),
(352, 'torres esteban', 'yessenia leisbith', '70344104', 'pj los geranios ', '', '931798874'),
(353, 'bravo lozano', 'luis cesar', '40309611', 'jr. moquegua 485 hyo', '', '964192342'),
(354, 'perez huaman', 'carlos anselmo', '41476156', 'jr. abancay 157 san carlos ', '', '944084855'),
(355, 'martinez dueñas', 'victor jesus', '44234034', 'prl cuszco 364 - hyo', '', '945901020'),
(356, 'vilcapoma mireya', 'mirella', '20121197', 'av catalina huanca 465', '', '970832599'),
(357, 'victoria flores', 'jonathan gustavo', '44607634', 'calle c mz r lt 12 hyo', '', '999977691'),
(358, 'nonalaya landa', 'erick', '20003739', 'san martin 149', '', '966056362'),
(359, 'apolinarez robles', 'eli jhonel', '41938540', 'calle rosario 189', '', '954005658'),
(360, 'galindez romero', 'rudy wilfredo', '40764600', 'pasj.los tulipanes 178 b -tambo', '', '982243322'),
(361, 'dorregaray flores', 'yasira ivette', '48246342', 'jr. rosa perz 460 - chupaca', '', '987859342'),
(362, 'gamarra palomino de coz', 'luz esther', '19822507', 'av.ferrocarril 1675 - huancayo ', '', '950602397'),
(363, 'sosa cerron', 'anthony', '48801771', 'jr. jose olaya 258', 'anthonyperu@gmail.com', '936894557'),
(364, 'rivera zamudio', 'nicelio', '19833634', 'corel santivañez 949 san carlos', '', '947513600'),
(365, 'orellana diaz', 'yanina jeydi', '77231172', 'jr. faustino quispe 176', '', '934477215'),
(366, 'tovar quispe', 'elizabeth norma', '80009658', 'calle alejandro o destua 107 el tambo', '', '983914898'),
(367, 'encalada picho', 'natali', '70781897', 'urb. mirian de salas 354-el tambo', '', '949380302'),
(368, 'bravo morales', 'jhonson rodney', '41597718', 'av leandro torres 551', '', '954080904'),
(369, 'tello cardenas', 'giovanni edward', '40974870', 'psj. los diamantes 265', '', '999043221'),
(370, 'vilcahuaman rodriguez', 'feliz henry', '43053023', 'jr. nemesio raez 540', '', '971548775'),
(371, 'manturano huamanchao', 'keelvin orlando', '48286891', 'jr. maria arguedas 647, el tambo', '', '948230640'),
(372, 'sosa valverde', 'jorge luis', '41234465', 'av progreso 439-el tambo', '', '967310270'),
(373, 'martinez vitor', 'manuel david', '19812410', 'jr libertad 552', '', '964743279'),
(374, 'espinoza alzamora', 'maribel', '20084755', 'pj el pinar 157- la rivera', '', '963835624'),
(375, 'areche zapata', 'edith janeth', '80005845', 'prol jorge chavez 343-el tambo', '', '931098428'),
(376, 'breña via y rada', 'katiuska susan', '42060102', 'jr. wari 325 - el tambo', '', '945087060'),
(377, 'bazan pagan', 'angello jorginho', '48486209', 'av. tahuantinsuyo 1031', '', '993941152'),
(378, 'carhuancho valdez', 'brandon italo', '76796799', 'jr. huancavelica 1851', '', '989262836'),
(379, 'lauro cangahuala', 'luis ananias', '42929335', 'jr. aguirre 600- el tambo', '', '938139550'),
(380, 'de la cruz coronel', 'carlos', '71494286', 'av santivañez 1248', '', '927794372'),
(381, 'palomino medina', 'sally', '70346865', 'av jose olaya 134 - 34', '', '920435507'),
(382, 'baldeon vega', 'luis enrique', '73127203', 'jr alejandro deustua 1200- el tambo', '', '997368573'),
(383, 'flores terrazos', 'oscar nicolas', '45360349', 'las gemas 109-covica', '', '930701828'),
(384, 'antoya palacios', 'ana', '19843244', 'junin 578 el tambo', '', '999245193'),
(385, 'nuñez quincho', 'david', '48823392', 'huamamarca sn ', '', '954802553');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Compras`
--

CREATE TABLE `Compras` (
  `idCompra` int(11) NOT NULL,
  `compNombre` varchar(200) NOT NULL,
  `compMontoInicial` float NOT NULL,
  `compFechaInicial` date NOT NULL,
  `compObservaciones` text NOT NULL,
  `idCliente` int(11) NOT NULL,
  `compActivo` bit(1) NOT NULL,
  `compFechaRegistro` datetime NOT NULL,
  `idUsuario` int(11) NOT NULL,
  `idSucursal` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `desembolso`
--

CREATE TABLE `desembolso` (
  `idDesembolso` int(11) NOT NULL,
  `idPrestamo` int(11) NOT NULL,
  `desCapital` float NOT NULL,
  `desDebeInteres` float NOT NULL DEFAULT '0',
  `desFechaContarInteres` datetime NOT NULL,
  `desFechaRegistro` datetime NOT NULL,
  `desActivo` int(11) NOT NULL,
  `desUsuario` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `desembolso`
--

INSERT INTO `desembolso` (`idDesembolso`, `idPrestamo`, `desCapital`, `desDebeInteres`, `desFechaContarInteres`, `desFechaRegistro`, `desActivo`, `desUsuario`) VALUES
(1, 1, 50, 0, '2017-01-07 00:00:00', '2017-02-06 12:29:21', 1, 2),
(2, 2, 200, 0, '2017-01-13 00:00:00', '2017-02-06 12:42:39', 1, 2),
(3, 3, 26, 0, '2017-02-16 00:00:00', '2017-02-06 13:00:15', 1, 2),
(4, 4, 252, 0, '2017-02-23 00:00:00', '2017-02-06 13:04:22', 1, 2),
(5, 5, 60, 0, '2017-01-19 00:00:00', '2017-02-06 13:08:30', 1, 2),
(6, 6, 500, 0, '2017-01-19 00:00:00', '2017-02-06 13:26:03', 1, 2),
(7, 7, 350, 0, '2017-01-20 00:00:00', '2017-02-06 13:30:46', 1, 2),
(8, 8, 48, 0, '2017-02-24 00:00:00', '2017-02-06 13:36:28', 1, 2),
(9, 9, 400, 0, '2017-01-26 00:00:00', '2017-02-06 13:45:32', 1, 2),
(10, 10, 51.2, 0, '2017-04-08 00:00:00', '2017-02-06 13:52:49', 1, 2),
(11, 11, 500, 0, '2017-02-03 00:00:00', '2017-02-06 13:56:58', 1, 2),
(12, 12, 150, 0, '2017-02-06 00:00:00', '2017-02-06 14:03:55', 1, 2),
(13, 13, 100, 0, '2017-01-10 00:00:00', '2017-02-06 14:19:15', 1, 2),
(14, 14, 105, 0, '2017-01-11 00:00:00', '2017-02-06 14:38:37', 1, 2),
(15, 15, 25.2, 0, '2017-03-25 00:00:00', '2017-02-07 17:46:08', 1, 2),
(16, 16, 100, 0, '2017-02-07 00:00:00', '2017-02-07 17:51:17', 1, 2),
(17, 17, 336, 0, '2017-03-06 00:00:00', '2017-02-07 17:54:08', 1, 2),
(18, 18, 170, 0, '2017-02-07 00:00:00', '2017-02-07 17:57:25', 1, 2),
(19, 19, 168, 0, '2017-03-13 00:00:00', '2017-02-08 15:20:29', 1, 2),
(20, 20, 200, 0, '2017-02-09 00:00:00', '2017-02-09 16:39:09', 1, 2),
(21, 21, 80, 0, '2017-02-09 00:00:00', '2017-02-09 18:34:00', 1, 2),
(22, 22, 450, 0, '2016-09-05 00:00:00', '2017-02-09 19:12:54', 1, 2),
(23, 23, 700, 0, '2016-10-28 00:00:00', '2017-02-09 19:16:56', 1, 2),
(51, 51, 300, 0, '2016-09-30 00:00:00', '2017-02-10 16:27:41', 1, 2),
(26, 26, 80, 0, '2016-10-04 00:00:00', '2017-02-09 19:30:32', 1, 2),
(27, 27, 590, 0, '2016-10-11 00:00:00', '2017-02-09 19:33:28', 1, 2),
(28, 28, 520, 0, '2016-10-13 00:00:00', '2017-02-09 19:35:55', 1, 2),
(29, 29, 200, 0, '2016-10-25 00:00:00', '2017-02-09 19:41:13', 1, 2),
(30, 30, 200, 0, '2016-10-26 00:00:00', '2017-02-09 19:43:04', 1, 2),
(31, 31, 200, 0, '2016-11-11 00:00:00', '2017-02-09 19:46:47', 1, 2),
(32, 32, 200, 0, '2016-11-14 00:00:00', '2017-02-09 19:50:07', 1, 2),
(33, 33, 1000, 0, '2016-11-15 00:00:00', '2017-02-09 19:52:48', 1, 2),
(34, 34, 150, 0, '2016-11-15 00:00:00', '2017-02-09 19:54:32', 1, 2),
(35, 35, 70, 0, '2016-11-16 00:00:00', '2017-02-09 19:56:18', 1, 2),
(36, 36, 100, 0, '2016-11-17 00:00:00', '2017-02-09 19:58:05', 1, 2),
(37, 37, 500, 0, '2016-11-19 00:00:00', '2017-02-09 19:59:57', 1, 2),
(38, 38, 60, 0, '2016-11-28 00:00:00', '2017-02-09 20:01:48', 1, 2),
(50, 50, 600, 0, '2016-09-28 00:00:00', '2017-02-10 16:25:09', 1, 2),
(40, 40, 350, 0, '2016-12-03 00:00:00', '2017-02-09 20:05:36', 1, 2),
(41, 41, 80, 0, '2016-12-12 00:00:00', '2017-02-09 20:07:48', 1, 2),
(42, 42, 68, 0, '2017-02-15 00:00:00', '2017-02-09 20:09:44', 1, 2),
(43, 43, 550, 0, '2016-12-14 00:00:00', '2017-02-09 20:11:52', 1, 2),
(44, 44, 400, 0, '2016-12-15 00:00:00', '2017-02-09 20:13:30', 1, 2),
(45, 45, 180, 0, '2016-12-16 00:00:00', '2017-02-09 20:15:14', 1, 2),
(46, 46, 60, 0, '2016-12-01 00:00:00', '2017-02-09 20:17:13', 1, 2),
(47, 47, 800, 0, '2017-01-06 00:00:00', '2017-02-09 20:19:06', 1, 2),
(48, 48, 500, 0, '2017-01-07 00:00:00', '2017-02-09 20:20:40', 1, 2),
(49, 49, 500, 0, '2017-02-10 00:00:00', '2017-02-10 12:33:53', 1, 2),
(52, 52, 300, 0, '2016-12-01 00:00:00', '2017-02-10 16:47:31', 1, 2),
(53, 53, 60, 0, '2017-02-10 00:00:00', '2017-02-10 18:18:09', 1, 2),
(54, 54, 80, 0, '2017-02-11 00:00:00', '2017-02-11 12:10:09', 1, 2),
(55, 55, 19, 0, '2017-03-03 00:00:00', '2017-02-13 12:43:31', 1, 9),
(56, 56, 160, 0, '2017-02-24 00:00:00', '2017-02-13 12:44:43', 1, 9),
(57, 57, 50, 0, '2017-02-13 00:00:00', '2017-02-13 15:32:14', 1, 2),
(58, 58, 700, 0, '2017-02-13 00:00:00', '2017-02-13 16:03:28', 1, 2),
(59, 59, 170, 0, '2017-02-20 00:00:00', '2017-02-13 16:34:48', 1, 2),
(60, 60, 300, 0, '2017-02-13 00:00:00', '2017-02-13 17:27:00', 1, 2),
(61, 61, 300, 0, '2017-02-13 00:00:00', '2017-02-13 17:49:57', 1, 2),
(62, 62, 107, 0, '2017-02-13 00:00:00', '2017-02-13 19:00:44', 1, 2),
(63, 63, 100, 0, '2017-02-14 00:00:00', '2017-02-14 11:06:32', 1, 2),
(64, 64, 140, 0, '2017-02-15 00:00:00', '2017-02-14 14:05:50', 1, 9),
(65, 65, 100, 0, '2017-02-14 00:00:00', '2017-02-14 14:31:23', 1, 10),
(66, 66, 80, 0, '2017-02-15 00:00:00', '2017-02-15 13:30:53', 1, 2),
(67, 67, 40, 0, '2017-02-16 00:00:00', '2017-02-16 13:58:46', 1, 2),
(68, 68, 200, 0, '2017-02-20 00:00:00', '2017-02-20 10:27:08', 1, 2),
(69, 69, 100, 0, '2017-02-20 00:00:00', '2017-02-20 12:20:53', 1, 2),
(70, 70, 101, 0, '2017-04-03 00:00:00', '2017-02-20 12:57:52', 1, 2),
(71, 71, 100, 0, '2017-02-20 00:00:00', '2017-02-20 14:08:25', 1, 2),
(72, 72, 500, 0, '2017-02-21 00:00:00', '2017-02-21 09:52:04', 1, 2),
(73, 73, 100, 0, '2017-02-22 00:00:00', '2017-02-22 16:50:08', 1, 2),
(74, 74, 1000, 0, '2017-02-23 00:00:00', '2017-02-23 19:01:40', 1, 2),
(75, 75, 300, 0, '2017-02-24 00:00:00', '2017-02-24 09:49:29', 1, 2),
(76, 76, 160, 0, '2017-04-28 00:00:00', '2017-02-24 18:07:38', 1, 2),
(77, 77, 2000, 0, '2017-02-24 00:00:00', '2017-02-24 19:26:10', 1, 2),
(78, 78, 2000, 0, '2017-02-24 00:00:00', '2017-02-24 19:26:11', 1, 2),
(79, 79, 400, 0, '2017-02-28 00:00:00', '2017-02-28 12:02:23', 1, 2),
(80, 80, 150, 0, '2017-02-28 00:00:00', '2017-02-28 13:56:43', 1, 2),
(81, 81, 600, 0, '2017-03-01 00:00:00', '2017-03-01 13:09:24', 1, 2),
(82, 82, 1500, 0, '2017-03-02 00:00:00', '2017-03-02 17:55:57', 1, 2),
(83, 83, 300, 0, '2017-03-04 00:00:00', '2017-03-04 12:37:50', 1, 2),
(84, 84, 300, 0, '2017-03-04 00:00:00', '2017-03-04 13:31:52', 1, 2),
(85, 85, 400, 0, '2017-03-06 00:00:00', '2017-03-06 11:56:47', 1, 2),
(86, 86, 1200, 0, '2017-03-07 00:00:00', '2017-03-07 15:37:02', 1, 2),
(87, 87, 756, 0, '2017-04-11 00:00:00', '2017-03-09 12:46:02', 1, 2),
(88, 88, 30, 0, '2017-03-09 00:00:00', '2017-03-09 17:25:37', 1, 2),
(89, 89, 850, 0, '2017-03-10 00:00:00', '2017-03-10 11:51:58', 1, 2),
(90, 90, 50, 0, '2017-03-10 00:00:00', '2017-03-10 14:36:47', 1, 2),
(91, 91, 300, 0, '2017-03-10 00:00:00', '2017-03-10 15:03:28', 1, 2),
(92, 92, 150, 0, '2017-03-11 00:00:00', '2017-03-11 10:06:40', 1, 2),
(93, 93, 140, 0, '2017-03-11 00:00:00', '2017-03-11 11:06:00', 1, 2),
(94, 94, 350, 0, '2017-03-13 00:00:00', '2017-03-13 20:37:08', 1, 2),
(95, 95, 230, 0, '2017-03-14 00:00:00', '2017-03-14 14:05:24', 1, 2),
(96, 96, 1100, 0, '2017-03-17 00:00:00', '2017-03-17 13:13:35', 1, 2),
(97, 97, 500, 0, '2017-03-17 00:00:00', '2017-03-17 14:00:39', 1, 2),
(98, 98, 400, 0, '2017-03-18 00:00:00', '2017-03-18 13:03:20', 1, 2),
(99, 99, 150, 0, '2017-03-20 00:00:00', '2017-03-20 15:47:54', 1, 2),
(100, 100, 1000, 0, '2017-03-20 00:00:00', '2017-03-20 20:19:35', 1, 2),
(101, 101, 350, 0, '2017-03-21 00:00:00', '2017-03-21 14:24:41', 1, 2),
(102, 102, 200, 0, '2017-03-22 00:00:00', '2017-03-22 12:26:06', 1, 2),
(103, 103, 200, 0, '2017-03-23 00:00:00', '2017-03-23 16:48:58', 1, 2),
(104, 104, 280, 0, '2017-03-24 00:00:00', '2017-03-24 18:18:45', 1, 2),
(105, 105, 300, 0, '2017-03-24 00:00:00', '2017-03-24 19:36:17', 1, 2),
(106, 106, 1200, 0, '2017-03-25 00:00:00', '2017-03-25 16:09:31', 1, 2),
(107, 107, 130, 0, '2017-03-28 00:00:00', '2017-03-28 11:39:31', 1, 2),
(108, 108, 200, 0, '2017-03-28 00:00:00', '2017-03-28 13:39:52', 1, 2),
(109, 109, 70, 0, '2017-03-28 00:00:00', '2017-03-28 17:17:27', 1, 2),
(110, 110, 2500, 0, '2017-03-29 00:00:00', '2017-03-29 12:58:02', 1, 2),
(111, 111, 800, 0, '2017-03-31 00:00:00', '2017-03-31 16:59:12', 1, 2),
(112, 112, 500, 0, '2017-03-31 00:00:00', '2017-03-31 17:15:52', 1, 2),
(113, 113, 300, 0, '2017-03-31 00:00:00', '2017-03-31 17:29:07', 1, 2),
(114, 114, 250, 0, '2017-03-31 00:00:00', '2017-03-31 19:43:38', 1, 2),
(115, 115, 300, 0, '2017-04-01 00:00:00', '2017-04-01 09:20:44', 1, 2),
(116, 116, 300, 0, '2017-04-01 00:00:00', '2017-04-01 15:56:38', 1, 2),
(117, 117, 300, 0, '2017-04-01 00:00:00', '2017-04-01 15:59:14', 1, 2),
(118, 118, 500, 0, '2017-04-03 00:00:00', '2017-04-03 18:56:12', 1, 2),
(119, 119, 2500, 0, '2017-04-04 00:00:00', '2017-04-04 17:20:33', 1, 2),
(120, 120, 600, 0, '2017-04-04 00:00:00', '2017-04-05 13:02:52', 1, 2),
(121, 121, 80, 0, '2017-04-17 00:00:00', '2017-04-05 16:57:12', 1, 9),
(122, 122, -666, 0, '2017-07-06 00:00:00', '2017-04-07 10:14:24', 1, 2),
(123, 123, 70, 0, '2017-04-07 00:00:00', '2017-04-07 12:12:28', 1, 2),
(124, 124, 250, 0, '2017-04-07 00:00:00', '2017-04-07 12:38:52', 1, 2),
(125, 125, 350, 0, '2017-04-09 00:00:00', '2017-04-09 14:03:07', 1, 2),
(126, 126, 150, 0, '2017-04-10 00:00:00', '2017-04-10 17:44:43', 1, 2),
(127, 127, 64, 0, '2017-05-11 00:00:00', '2017-04-10 18:37:40', 1, 2),
(128, 128, 0, 0, '2017-04-17 00:00:00', '2017-04-11 10:27:05', 1, 2),
(129, 129, 200, 0, '2017-07-17 00:00:00', '2017-04-11 10:50:20', 1, 2),
(130, 130, 40, 0, '2017-06-19 00:00:00', '2017-04-11 11:07:14', 1, 2),
(131, 131, 1500, 0, '2017-04-11 00:00:00', '2017-04-11 14:57:54', 1, 2),
(132, 132, 300, 0, '2017-04-08 00:00:00', '2017-04-11 17:25:14', 1, 2),
(133, 133, 200, 0, '2017-04-11 00:00:00', '2017-04-11 18:27:59', 1, 2),
(134, 134, 200, 0, '2017-04-12 00:00:00', '2017-04-12 11:53:44', 1, 2),
(135, 135, 150, 0, '2017-04-12 00:00:00', '2017-04-12 12:02:53', 1, 2),
(136, 136, 200, 0, '2017-04-12 00:00:00', '2017-04-12 12:24:15', 1, 2),
(137, 137, 300, 0, '2017-04-12 00:00:00', '2017-04-12 16:28:45', 1, 2),
(138, 138, 150, 0, '2017-04-12 00:00:00', '2017-04-12 17:35:50', 1, 2),
(139, 139, 350, 0, '2017-04-13 00:00:00', '2017-04-13 10:58:40', 1, 2),
(140, 140, 90, 0, '2017-04-17 00:00:00', '2017-04-17 11:20:34', 1, 9),
(141, 141, 300, 0, '2017-04-17 00:00:00', '2017-04-17 12:09:16', 1, 9),
(142, 142, 200, 0, '2017-04-17 00:00:00', '2017-04-17 12:33:11', 1, 9),
(143, 143, 150, 0, '2017-04-17 00:00:00', '2017-04-17 12:44:39', 1, 2),
(144, 144, 70, 0, '2017-04-17 00:00:00', '2017-04-17 13:10:48', 1, 2),
(145, 145, 400, 0, '2017-04-17 00:00:00', '2017-04-17 18:52:03', 1, 2),
(146, 146, 200, 0, '2017-04-18 00:00:00', '2017-04-18 15:50:25', 1, 2),
(147, 147, 300, 0, '2017-04-19 00:00:00', '2017-04-19 16:54:45', 1, 2),
(148, 148, 350, 0, '2017-04-20 00:00:00', '2017-04-20 11:26:55', 1, 2),
(149, 149, 300, 0, '2017-04-20 00:00:00', '2017-04-20 16:37:59', 1, 2),
(150, 150, 300, 0, '2017-04-20 00:00:00', '2017-04-20 18:29:19', 1, 2),
(151, 151, 70, 0, '2017-04-21 00:00:00', '2017-04-21 09:57:44', 1, 2),
(152, 152, 300, 0, '2017-04-21 00:00:00', '2017-04-21 17:42:29', 1, 2),
(153, 153, 1700, 0, '2017-04-22 00:00:00', '2017-04-22 12:33:52', 1, 2),
(154, 154, 150, 0, '2017-04-24 00:00:00', '2017-04-24 14:03:59', 1, 2),
(155, 155, 200, 0, '2017-04-26 00:00:00', '2017-04-26 16:42:52', 1, 2),
(156, 156, 300, 0, '2017-04-27 00:00:00', '2017-04-27 09:54:04', 1, 2),
(157, 157, 240, 0, '2017-04-27 00:00:00', '2017-04-27 10:01:44', 1, 2),
(158, 158, 50, 0, '2017-04-27 00:00:00', '2017-04-27 12:06:04', 1, 2),
(159, 159, 90, 0, '2017-04-27 00:00:00', '2017-04-27 17:09:21', 1, 2),
(160, 160, 4000, 0, '2017-04-28 00:00:00', '2017-04-28 13:30:45', 1, 2),
(161, 161, 300, 0, '2017-04-28 00:00:00', '2017-04-28 14:50:03', 1, 2),
(162, 162, 100, 0, '2017-04-28 00:00:00', '2017-04-28 18:55:43', 1, 2),
(163, 163, 200, 0, '2017-04-29 00:00:00', '2017-04-29 12:24:16', 1, 2),
(164, 164, 250, 0, '2017-04-02 00:00:00', '2017-05-02 09:20:19', 1, 2),
(165, 165, -20, 0, '2017-05-06 00:00:00', '2017-05-03 14:26:13', 1, 2),
(166, 166, 50, 0, '2017-05-04 00:00:00', '2017-05-04 13:43:19', 1, 9),
(167, 167, 15, 0, '2017-05-04 00:00:00', '2017-05-04 13:44:50', 1, 9),
(168, 168, 300, 0, '2017-05-08 00:00:00', '2017-05-08 11:24:29', 1, 2),
(169, 169, 800, 0, '2017-07-10 00:00:00', '2017-05-08 14:43:09', 1, 2),
(170, 170, 500, 0, '2017-05-09 00:00:00', '2017-05-09 18:53:24', 1, 2),
(171, 171, 500, 0, '2017-05-10 00:00:00', '2017-05-10 17:17:11', 1, 2),
(172, 172, 15, 0, '2017-06-14 00:00:00', '2017-05-11 11:17:08', 1, 9),
(173, 173, 400, 0, '2017-05-11 00:00:00', '2017-05-11 13:37:13', 1, 2),
(174, 174, 400, 0, '2017-05-11 00:00:00', '2017-05-11 15:09:36', 1, 2),
(175, 175, 130, 0, '2017-06-20 00:00:00', '2017-05-11 17:54:02', 1, 9),
(176, 176, 150, 0, '2017-05-11 00:00:00', '2017-05-11 18:38:01', 1, 9),
(177, 177, 4500, 0, '2017-05-12 00:00:00', '2017-05-12 14:55:11', 1, 2),
(178, 178, 170, 0, '2017-05-12 00:00:00', '2017-05-12 16:58:56', 1, 2),
(179, 179, 250, 0, '2017-05-12 00:00:00', '2017-05-12 17:32:41', 1, 2),
(180, 180, 100, 0, '2017-05-12 00:00:00', '2017-05-12 18:10:03', 1, 2),
(181, 181, 350, 0, '2017-05-13 00:00:00', '2017-05-13 12:56:26', 1, 2),
(182, 182, 300, 0, '2017-05-15 00:00:00', '2017-05-15 09:44:20', 1, 2),
(183, 183, 400, 0, '2017-05-15 00:00:00', '2017-05-15 12:25:44', 1, 2),
(184, 184, 300, 0, '2017-07-18 00:00:00', '2017-05-15 17:26:59', 1, 2),
(185, 185, 200, 0, '2017-06-19 00:00:00', '2017-05-16 14:44:46', 1, 3),
(186, 186, 60, 0, '2017-05-17 00:00:00', '2017-05-17 18:28:56', 1, 3),
(187, 187, 600, 0, '2017-05-18 00:00:00', '2017-05-18 15:35:53', 1, 2),
(188, 188, 200, 0, '2017-05-18 00:00:00', '2017-05-18 16:05:05', 1, 2),
(189, 189, 250, 0, '2017-05-19 00:00:00', '2017-05-19 11:30:52', 1, 3),
(190, 190, 300, 0, '2017-05-19 00:00:00', '2017-05-19 12:49:21', 1, 3),
(191, 191, 300, 0, '2017-05-19 00:00:00', '2017-05-19 14:15:00', 1, 3),
(192, 192, 2500, 0, '2017-05-19 00:00:00', '2017-05-19 15:40:26', 1, 3),
(193, 193, 350, 0, '2017-05-19 00:00:00', '2017-05-19 16:30:14', 1, 3),
(194, 194, 300, 0, '2017-05-19 00:00:00', '2017-05-19 17:08:42', 1, 3),
(195, 195, 150, 0, '2017-05-20 00:00:00', '2017-05-20 10:17:37', 1, 3),
(196, 196, 70, 0, '2017-05-20 00:00:00', '2017-05-20 13:59:32', 1, 3),
(197, 197, 300, 0, '2017-07-06 00:00:00', '2017-05-22 12:16:32', 1, 3),
(198, 198, 6000, 0, '2017-05-22 00:00:00', '2017-05-22 16:39:56', 1, 3),
(199, 199, 1500, 0, '2017-08-16 00:00:00', '2017-05-22 18:13:17', 1, 3),
(200, 200, 50, 0, '2017-05-22 00:00:00', '2017-05-22 19:07:09', 1, 3),
(201, 201, 150, 0, '2017-05-23 00:00:00', '2017-05-23 18:09:44', 1, 3),
(202, 202, 100, 0, '2017-05-24 00:00:00', '2017-05-24 14:50:47', 1, 3),
(203, 203, 200, 0, '2017-07-05 00:00:00', '2017-05-24 15:04:50', 1, 3),
(204, 204, 200, 0, '2017-05-25 00:00:00', '2017-05-25 16:47:11', 1, 3),
(205, 205, 400, 0, '2017-05-25 00:00:00', '2017-05-25 17:27:36', 1, 3),
(206, 206, 100, 0, '2017-05-25 00:00:00', '2017-05-25 18:59:01', 1, 3),
(207, 207, 450, 0, '2017-05-26 00:00:00', '2017-05-26 09:33:03', 1, 3),
(208, 208, 500, 0, '2017-06-23 00:00:00', '2017-05-26 10:29:05', 1, 3),
(209, 209, 50, 0, '2017-05-26 00:00:00', '2017-05-26 15:40:53', 1, 3),
(210, 210, 500, 0, '2017-05-27 00:00:00', '2017-05-27 09:15:30', 1, 9),
(211, 211, 1000, 0, '2017-05-29 00:00:00', '2017-05-29 11:56:44', 1, 3),
(212, 212, 6000, 0, '2017-05-29 00:00:00', '2017-05-29 18:21:35', 1, 3),
(213, 213, 100, 0, '2017-05-30 00:00:00', '2017-05-30 09:26:58', 1, 3),
(214, 214, 200, 0, '2017-05-30 00:00:00', '2017-05-30 15:41:29', 1, 3),
(215, 215, 200, 0, '2017-05-30 00:00:00', '2017-05-30 17:18:04', 1, 3),
(216, 216, 250, 0, '2017-05-30 00:00:00', '2017-05-30 19:15:08', 1, 3),
(217, 217, 200, 0, '2017-06-02 00:00:00', '2017-06-02 10:18:34', 1, 3),
(218, 218, 300, 0, '2017-06-02 00:00:00', '2017-06-02 13:09:13', 1, 3),
(219, 219, 150, 0, '2017-06-18 00:00:00', '2017-06-02 17:54:37', 1, 3),
(220, 220, 200, 0, '2017-06-02 00:00:00', '2017-06-02 18:11:22', 1, 3),
(221, 221, 180, 0, '2017-06-03 00:00:00', '2017-06-03 11:49:01', 1, 12),
(222, 222, 350, 0, '2017-06-03 00:00:00', '2017-06-03 12:16:19', 1, 12),
(223, 223, 400, 0, '2017-08-07 00:00:00', '2017-06-05 10:50:27', 1, 3),
(224, 224, 200, 0, '2017-06-05 00:00:00', '2017-06-05 11:50:28', 1, 3),
(225, 225, 120, 0, '2017-06-05 00:00:00', '2017-06-05 12:17:00', 1, 3),
(226, 226, 350, 0, '2017-06-05 00:00:00', '2017-06-05 15:11:28', 1, 3),
(227, 227, 70, 0, '2017-06-05 00:00:00', '2017-06-05 17:22:02', 1, 3),
(228, 228, 50, 0, '2017-06-05 00:00:00', '2017-06-05 18:31:09', 1, 3),
(229, 229, 3200, 0, '2017-06-05 00:00:00', '2017-06-05 18:47:18', 1, 3),
(230, 230, 150, 0, '2017-06-06 00:00:00', '2017-06-06 14:24:55', 1, 3),
(231, 231, 300, 0, '2017-06-06 00:00:00', '2017-06-06 16:05:21', 1, 3),
(232, 232, 450, 0, '2017-06-07 00:00:00', '2017-06-07 18:04:01', 1, 3),
(233, 233, 8000, 0, '2017-05-29 00:00:00', '2017-06-07 18:47:14', 1, 3),
(234, 234, 450, 0, '2017-06-07 00:00:00', '2017-06-07 18:56:53', 1, 3),
(235, 235, 450, 0, '2017-06-08 00:00:00', '2017-06-08 10:45:43', 1, 3),
(236, 236, 300, 0, '2017-06-08 00:00:00', '2017-06-08 11:20:13', 1, 3),
(237, 237, 100, 0, '2017-06-08 00:00:00', '2017-06-08 13:11:20', 1, 3),
(238, 238, 300, 0, '2017-08-17 00:00:00', '2017-06-08 17:34:34', 1, 3),
(239, 239, 40, 0, '2017-06-09 00:00:00', '2017-06-09 14:01:01', 1, 12),
(240, 240, 800, 0, '2017-06-09 00:00:00', '2017-06-09 14:38:29', 1, 12),
(241, 241, 60, 0, '2017-06-10 00:00:00', '2017-06-12 09:37:51', 1, 3),
(242, 242, 100, 0, '2017-06-18 00:00:00', '2017-06-12 09:39:53', 1, 3),
(243, 243, 400, 0, '2017-06-10 00:00:00', '2017-06-12 09:51:42', 1, 3),
(244, 244, 80, 0, '2017-06-12 00:00:00', '2017-06-12 10:00:16', 1, 3),
(245, 245, 4100, 0, '2017-06-12 00:00:00', '2017-06-12 18:52:55', 1, 3),
(246, 246, 170, 0, '2017-06-13 00:00:00', '2017-06-13 10:43:05', 1, 3),
(247, 247, 150, 0, '2017-06-13 00:00:00', '2017-06-13 11:02:18', 1, 3),
(248, 248, 50, 0, '2017-07-17 00:00:00', '2017-06-13 16:25:50', 1, 3),
(249, 249, 450, 0, '2017-06-13 00:00:00', '2017-06-13 18:31:21', 1, 3),
(251, 251, 4000, 0, '2017-06-14 00:00:00', '2017-06-14 11:37:24', 1, 3),
(252, 252, 50, 0, '2017-06-14 00:00:00', '2017-06-14 17:06:36', 1, 3),
(253, 253, 600, 0, '2017-07-10 00:00:00', '2017-06-15 09:44:33', 1, 3),
(254, 254, 150, 0, '2017-06-15 00:00:00', '2017-06-15 11:27:05', 1, 3),
(255, 255, 600, 0, '2017-06-15 00:00:00', '2017-06-15 12:41:47', 1, 3),
(256, 256, 228, 0, '2017-07-22 00:00:00', '2017-06-15 12:50:49', 1, 3),
(257, 257, 330, 0, '2017-06-15 00:00:00', '2017-06-15 17:08:38', 1, 13),
(258, 258, 400, 0, '2017-06-16 00:00:00', '2017-06-16 09:52:43', 1, 3),
(259, 259, 300, 0, '2017-06-16 00:00:00', '2017-06-16 10:42:30', 1, 3),
(260, 260, 400, 0, '2017-06-16 00:00:00', '2017-06-16 11:06:37', 1, 3),
(261, 261, 150, 0, '2017-06-16 00:00:00', '2017-06-16 11:24:23', 1, 3),
(262, 262, 500, 0, '2017-06-16 00:00:00', '2017-06-16 17:14:49', 1, 3),
(263, 263, 400, 0, '2017-06-19 00:00:00', '2017-06-19 19:31:54', 1, 3),
(264, 264, 350, 0, '2017-06-19 00:00:00', '2017-06-19 20:18:15', 1, 13),
(265, 265, 450, 0, '2017-06-28 00:00:00', '2017-06-20 10:26:49', 1, 3),
(266, 266, 30, 0, '2017-06-21 00:00:00', '2017-06-21 10:55:53', 1, 3),
(267, 267, 150, 0, '2017-06-21 00:00:00', '2017-06-21 14:06:52', 1, 9),
(268, 268, 136, 0, '2017-06-21 00:00:00', '2017-06-21 14:29:41', 1, 9),
(269, 269, 55, 0, '2017-06-21 00:00:00', '2017-06-21 14:42:05', 1, 9),
(270, 270, 20, 0, '2017-06-21 00:00:00', '2017-06-21 16:55:04', 1, 9),
(271, 271, 15, 0, '2017-06-21 00:00:00', '2017-06-21 17:48:24', 1, 9),
(272, 272, 400, 0, '2017-06-22 00:00:00', '2017-06-22 10:27:58', 1, 3),
(273, 273, 800, 0, '2017-07-20 00:00:00', '2017-06-22 13:36:39', 1, 3),
(274, 274, 400, 0, '2017-06-23 00:00:00', '2017-06-23 15:19:30', 1, 3),
(275, 275, 90, 0, '2017-06-23 00:00:00', '2017-06-23 16:23:03', 1, 3),
(276, 276, 400, 0, '2017-08-28 00:00:00', '2017-06-23 16:44:51', 1, 3),
(277, 277, 80, 0, '2017-06-23 00:00:00', '2017-06-23 18:35:02', 1, 3),
(278, 278, 500, 0, '2017-06-23 00:00:00', '2017-06-23 19:26:31', 1, 3),
(279, 279, 200, 0, '2017-06-23 00:00:00', '2017-06-24 09:58:09', 1, 13),
(280, 280, 600, 0, '2017-06-23 00:00:00', '2017-06-24 10:01:19', 1, 13),
(281, 281, 200, 0, '2017-08-22 00:00:00', '2017-06-24 11:47:31', 1, 12),
(282, 282, 300, 0, '2017-06-26 00:00:00', '2017-06-26 09:51:12', 1, 3),
(283, 283, 100, 0, '2017-06-26 00:00:00', '2017-06-26 17:40:20', 1, 3),
(284, 284, 150, 0, '2017-06-24 00:00:00', '2017-06-26 20:08:10', 1, 13),
(285, 285, 70, 0, '2017-06-24 00:00:00', '2017-06-26 20:10:39', 1, 13),
(286, 286, 10000, 0, '2017-07-25 00:00:00', '2017-06-27 13:25:31', 1, 3),
(287, 287, 100, 0, '2017-06-28 00:00:00', '2017-06-28 16:09:58', 1, 3),
(288, 288, 600, 0, '2017-07-12 00:00:00', '2017-06-28 17:44:34', 1, 3),
(289, 289, 250, 0, '2017-06-30 00:00:00', '2017-06-30 15:48:40', 1, 13),
(290, 290, 210, 0, '2017-06-30 00:00:00', '2017-06-30 15:50:59', 1, 13),
(291, 291, 250, 0, '2017-06-30 00:00:00', '2017-06-30 17:31:11', 1, 3),
(292, 292, 1300, 0, '2017-06-30 00:00:00', '2017-06-30 18:18:37', 1, 3),
(293, 293, 2000, 0, '2017-06-30 00:00:00', '2017-06-30 19:37:53', 1, 3),
(294, 294, 250, 0, '2017-07-01 00:00:00', '2017-07-01 13:39:02', 1, 12),
(295, 295, 220, 0, '2017-07-01 00:00:00', '2017-07-01 14:23:38', 1, 12),
(296, 296, 350, 0, '2017-07-03 00:00:00', '2017-07-03 10:57:34', 1, 3),
(297, 297, 150, 0, '2017-07-03 00:00:00', '2017-07-03 14:41:54', 1, 3),
(298, 298, 600, 0, '2017-06-09 00:00:00', '2017-07-03 16:40:03', 1, 3),
(299, 299, 443, 0, '2017-07-03 00:00:00', '2017-07-03 19:18:29', 1, 9),
(300, 300, 750, 0, '2017-07-04 00:00:00', '2017-07-04 09:58:39', 1, 3),
(301, 301, 200, 0, '2017-07-04 00:00:00', '2017-07-04 11:54:25', 1, 3),
(302, 302, 60, 0, '2017-07-01 00:00:00', '2017-07-04 12:20:12', 1, 13),
(303, 303, 1300, 0, '2017-07-01 00:00:00', '2017-07-04 12:23:30', 1, 13),
(304, 304, 150, 0, '2017-07-04 00:00:00', '2017-07-04 18:12:36', 1, 3),
(305, 305, 700, 0, '2017-08-04 00:00:00', '2017-07-05 17:43:32', 1, 3),
(306, 306, 200, 0, '2017-07-05 00:00:00', '2017-07-05 21:09:13', 1, 13),
(307, 307, 230, 0, '2017-07-05 00:00:00', '2017-07-05 21:11:58', 1, 13),
(308, 308, 500, 0, '2017-06-23 00:00:00', '2017-07-07 12:09:14', 1, 9),
(309, 309, 104.4, 0, '2017-07-07 00:00:00', '2017-07-07 14:07:54', 1, 14),
(310, 310, 280, 0, '2017-07-08 00:00:00', '2017-07-08 12:33:01', 1, 12),
(311, 311, 450, 0, '2017-07-21 00:00:00', '2017-07-10 10:39:28', 1, 3),
(312, 312, 40, 0, '2017-07-10 00:00:00', '2017-07-10 10:49:27', 1, 3),
(313, 313, 1000, 0, '2017-07-11 00:00:00', '2017-07-11 11:24:29', 1, 8),
(314, 314, 80, 0, '2017-07-12 00:00:00', '2017-07-12 14:39:33', 1, 3),
(315, 315, 500, 0, '2017-07-12 00:00:00', '2017-07-12 16:32:33', 1, 3),
(316, 316, 150, 0, '2017-07-12 00:00:00', '2017-07-12 17:05:02', 1, 9),
(317, 317, 120, 0, '2017-07-12 00:00:00', '2017-07-12 18:45:48', 1, 9),
(318, 318, 400, 0, '2017-07-14 00:00:00', '2017-07-14 15:04:12', 1, 3),
(319, 319, 70, 0, '2017-07-15 00:00:00', '2017-07-15 11:28:41', 1, 12),
(320, 320, 500, 0, '2017-07-16 00:00:00', '2017-07-17 11:58:58', 1, 13),
(321, 321, 200, 0, '2017-06-07 00:00:00', '2017-07-17 20:10:07', 1, 3),
(322, 322, 100, 0, '2017-07-18 00:00:00', '2017-07-18 19:35:23', 1, 3),
(323, 323, 300, 0, '2017-07-19 00:00:00', '2017-07-19 10:35:59', 1, 3),
(324, 324, 200, 0, '2017-07-19 00:00:00', '2017-07-19 17:52:26', 1, 3),
(325, 325, 40, 0, '2017-07-19 00:00:00', '2017-07-19 18:09:41', 1, 3),
(326, 326, 70, 0, '2017-07-20 00:00:00', '2017-07-20 18:27:51', 1, 3),
(327, 327, 400, 0, '2017-07-20 00:00:00', '2017-07-20 18:51:17', 1, 3),
(328, 328, 130, 0, '2017-07-21 00:00:00', '2017-07-21 13:30:52', 1, 3),
(329, 329, 120, 0, '2017-07-22 00:00:00', '2017-07-22 12:48:51', 1, 12),
(330, 330, 200, 0, '2017-07-22 00:00:00', '2017-07-22 13:51:53', 1, 9),
(331, 331, 80, 0, '2017-07-25 00:00:00', '2017-07-25 10:55:41', 1, 3),
(332, 332, 150, 0, '2017-07-25 00:00:00', '2017-07-25 12:38:31', 1, 3),
(333, 333, 150, 0, '2017-07-28 00:00:00', '2017-07-28 11:00:37', 1, 3),
(334, 334, 200, 0, '2017-07-28 00:00:00', '2017-07-28 11:28:13', 1, 3),
(335, 335, 250, 0, '2017-07-28 00:00:00', '2017-07-28 16:03:03', 1, 3),
(336, 336, 250, 0, '2017-07-28 00:00:00', '2017-07-28 18:09:42', 1, 3),
(337, 337, 50, 0, '2017-07-27 00:00:00', '2017-07-29 11:03:31', 1, 13),
(338, 338, 380, 0, '2017-07-27 00:00:00', '2017-07-29 11:04:44', 1, 13),
(339, 339, 180, 0, '2017-07-27 00:00:00', '2017-07-29 11:09:32', 1, 13),
(340, 340, 1000, 0, '2017-07-27 00:00:00', '2017-07-29 11:12:43', 1, 13),
(341, 341, 200, 0, '2017-07-26 00:00:00', '2017-07-29 11:16:28', 1, 13),
(342, 342, 40, 0, '2017-08-28 00:00:00', '2017-07-29 11:18:55', 1, 13),
(343, 343, 80, 0, '2017-07-27 00:00:00', '2017-07-29 11:26:20', 1, 13),
(344, 344, 300, 0, '2017-07-25 00:00:00', '2017-07-29 11:33:15', 1, 13),
(345, 345, 15000, 0, '2017-07-31 00:00:00', '2017-07-31 14:05:52', 1, 3),
(346, 346, 150, 0, '2017-08-01 00:00:00', '2017-08-01 17:45:39', 1, 3),
(347, 347, 150, 0, '2017-08-02 00:00:00', '2017-08-02 12:21:30', 1, 3),
(348, 348, 150, 0, '2017-08-02 00:00:00', '2017-08-02 17:02:07', 1, 3),
(349, 349, 170, 0, '2017-08-02 00:00:00', '2017-08-02 19:14:08', 1, 3),
(350, 350, 400, 0, '2017-08-03 00:00:00', '2017-08-03 16:38:57', 1, 3),
(351, 351, 2000, 0, '2017-08-03 00:00:00', '2017-08-03 18:08:52', 1, 3),
(352, 352, 250, 0, '2017-09-08 00:00:00', '2017-08-07 17:40:34', 1, 3),
(353, 353, 1200, 0, '2017-08-07 00:00:00', '2017-08-07 17:53:56', 1, 3),
(354, 354, 300, 0, '2017-08-07 00:00:00', '2017-08-07 18:31:49', 1, 3),
(355, 355, 500, 0, '2017-08-08 00:00:00', '2017-08-08 15:05:42', 1, 3),
(356, 356, 250, 0, '2017-08-08 00:00:00', '2017-08-08 15:18:49', 1, 3),
(357, 357, 8000, 0, '2017-08-08 00:00:00', '2017-08-08 15:29:28', 1, 3),
(358, 358, 250, 0, '2017-08-08 00:00:00', '2017-08-08 17:45:03', 1, 3),
(359, 359, 250, 0, '2017-08-09 00:00:00', '2017-08-09 16:26:11', 1, 3),
(360, 360, 50, 0, '2017-08-10 00:00:00', '2017-08-10 10:36:23', 1, 3),
(361, 361, 5000, 0, '2017-08-11 00:00:00', '2017-08-11 12:06:58', 1, 3),
(362, 362, 400, 0, '2017-08-14 00:00:00', '2017-08-14 15:55:20', 1, 3),
(363, 363, 1000, 0, '2017-08-12 00:00:00', '2017-08-14 18:22:36', 1, 13),
(364, 364, 600, 0, '2017-08-12 00:00:00', '2017-08-14 18:24:19', 1, 13),
(365, 365, 200, 0, '2017-08-15 00:00:00', '2017-08-15 10:13:33', 1, 3),
(366, 366, 80, 0, '2017-08-15 00:00:00', '2017-08-15 10:52:12', 1, 3),
(367, 367, 60, 0, '2017-08-15 00:00:00', '2017-08-15 11:59:05', 1, 3),
(368, 368, 2000, 0, '2017-08-15 00:00:00', '2017-08-15 12:18:41', 1, 3),
(369, 369, 5000, 0, '2017-08-15 00:00:00', '2017-08-15 16:11:33', 1, 3),
(370, 370, 250, 0, '2017-08-16 00:00:00', '2017-08-16 10:13:16', 1, 3),
(371, 371, 1000, 0, '2017-08-16 00:00:00', '2017-08-16 10:36:17', 1, 3),
(372, 372, 450, 0, '2017-08-16 00:00:00', '2017-08-16 18:42:56', 1, 3),
(373, 373, 100, 0, '2017-08-17 00:00:00', '2017-08-17 10:20:23', 1, 3),
(374, 374, 50, 0, '2017-08-17 00:00:00', '2017-08-17 11:17:23', 1, 3),
(375, 375, 150, 0, '2017-08-17 00:00:00', '2017-08-17 12:25:59', 1, 3),
(376, 376, 250, 0, '2017-08-17 00:00:00', '2017-08-17 15:50:03', 1, 3),
(377, 377, 40, 0, '2017-08-17 00:00:00', '2017-08-17 19:18:29', 1, 3),
(378, 378, 500, 0, '2017-08-18 00:00:00', '2017-08-18 18:01:11', 1, 3),
(379, 379, 300, 0, '2017-08-19 00:00:00', '2017-08-19 09:54:07', 1, 12),
(380, 380, 30, 0, '2017-08-19 00:00:00', '2017-08-19 11:52:03', 1, 12),
(381, 381, 200, 0, '2017-08-21 00:00:00', '2017-08-21 16:35:37', 1, 3),
(382, 382, 500, 0, '2017-08-21 00:00:00', '2017-08-21 16:39:58', 1, 3),
(383, 383, 500, 0, '2017-09-04 00:00:00', '2017-08-21 16:53:39', 1, 3),
(384, 384, 700, 0, '2017-08-21 00:00:00', '2017-08-21 17:35:54', 1, 3),
(385, 385, 250, 0, '2017-08-21 00:00:00', '2017-08-21 19:07:43', 1, 3),
(386, 386, 850, 0, '2017-08-21 00:00:00', '2017-08-21 19:14:23', 1, 3),
(387, 387, 850, 0, '2017-08-21 00:00:00', '2017-08-21 19:14:27', 1, 3),
(388, 388, 450, 0, '2017-08-17 00:00:00', '2017-08-22 10:19:04', 1, 3),
(389, 389, 3000, 0, '2017-08-22 00:00:00', '2017-08-22 11:43:13', 1, 3),
(390, 390, 150, 0, '2017-08-23 00:00:00', '2017-08-23 12:43:00', 1, 3),
(391, 391, 750, 0, '2017-08-23 00:00:00', '2017-08-23 18:54:11', 1, 3),
(392, 392, 100, 0, '2017-08-24 00:00:00', '2017-08-24 10:16:09', 1, 3),
(393, 393, 600, 0, '2017-09-04 00:00:00', '2017-08-24 11:54:18', 1, 3),
(394, 394, 550, 0, '2017-08-17 00:00:00', '2017-08-24 12:04:23', 1, 3),
(395, 395, 400, 0, '2017-08-24 00:00:00', '2017-08-24 14:10:18', 1, 3),
(396, 396, 350, 0, '2017-08-24 00:00:00', '2017-08-24 16:34:48', 1, 3),
(397, 397, 1000, 0, '2017-08-25 00:00:00', '2017-08-25 09:35:04', 1, 8),
(398, 398, 1000, 0, '2017-08-25 00:00:00', '2017-08-25 13:14:57', 1, 3),
(399, 399, 400, 0, '2017-08-25 00:00:00', '2017-08-25 15:00:09', 1, 3),
(400, 400, 1000, 0, '2017-08-25 00:00:00', '2017-08-25 16:49:25', 1, 3),
(401, 401, 100, 0, '2017-08-25 00:00:00', '2017-08-25 18:57:06', 1, 3),
(402, 402, 300, 0, '2017-08-25 00:00:00', '2017-08-25 19:00:25', 1, 3),
(403, 403, 300, 0, '2017-08-25 00:00:00', '2017-08-25 19:09:52', 1, 3),
(404, 404, 200, 0, '2017-08-25 00:00:00', '2017-08-25 19:19:29', 1, 3),
(405, 405, 500, 0, '2017-08-28 00:00:00', '2017-08-28 09:46:35', 1, 3),
(406, 406, 18000, 0, '2017-08-28 00:00:00', '2017-08-28 10:01:22', 1, 3),
(407, 407, 700, 0, '2017-08-28 00:00:00', '2017-08-28 12:06:25', 1, 13),
(408, 408, 150, 0, '2017-08-28 00:00:00', '2017-08-28 12:09:27', 1, 13),
(409, 409, 100, 0, '2017-08-29 00:00:00', '2017-08-29 10:51:28', 1, 3),
(410, 410, 100, 0, '2017-09-05 00:00:00', '2017-08-29 10:58:57', 1, 3),
(411, 411, 200, 0, '2017-08-29 00:00:00', '2017-08-29 11:18:14', 1, 3),
(412, 412, 70, 0, '2017-08-29 00:00:00', '2017-08-29 13:49:46', 1, 3),
(413, 413, 300, 0, '2017-08-30 00:00:00', '2017-08-30 10:04:15', 1, 3),
(414, 414, 80, 0, '2017-08-30 00:00:00', '2017-08-30 18:51:21', 1, 3),
(415, 415, 300, 0, '2017-08-31 00:00:00', '2017-08-31 10:48:37', 1, 3),
(416, 416, 100, 0, '2017-08-31 00:00:00', '2017-08-31 16:51:37', 1, 9),
(417, 417, 900, 0, '2017-09-01 00:00:00', '2017-09-01 10:40:28', 1, 3),
(418, 418, 150, 0, '2017-09-01 00:00:00', '2017-09-01 12:18:25', 1, 3),
(419, 419, 300, 0, '2017-09-01 00:00:00', '2017-09-01 16:01:19', 1, 3),
(420, 420, 700, 0, '2017-09-01 00:00:00', '2017-09-01 18:11:15', 1, 3),
(421, 421, 1500, 0, '2017-09-02 00:00:00', '2017-09-02 12:54:57', 1, 12),
(422, 422, 450, 0, '2017-09-04 00:00:00', '2017-09-04 10:26:13', 1, 3),
(423, 423, 1000, 0, '2017-09-04 00:00:00', '2017-09-04 15:43:19', 1, 3),
(424, 424, 1000, 0, '2017-09-04 00:00:00', '2017-09-04 17:43:38', 1, 3),
(425, 425, 3000, 0, '2017-09-04 00:00:00', '2017-09-04 18:01:29', 1, 13),
(426, 426, 1500, 0, '2017-09-04 00:00:00', '2017-09-04 18:53:34', 1, 3),
(427, 427, 150, 0, '2017-09-05 00:00:00', '2017-09-05 12:54:50', 1, 3),
(428, 428, 500, 0, '2017-09-05 00:00:00', '2017-09-05 15:08:06', 1, 3),
(429, 429, 100, 0, '2017-09-05 00:00:00', '2017-09-05 17:39:07', 1, 13),
(430, 430, 100, 0, '2017-08-23 00:00:00', '2017-09-05 17:40:14', 1, 13),
(442, 442, 500, 0, '2017-09-05 00:00:00', '2017-09-05 19:45:17', 1, 3),
(433, 433, 350, 0, '2017-08-17 00:00:00', '2017-08-17 17:46:13', 1, 13),
(434, 434, 900, 0, '2017-09-01 00:00:00', '2017-09-05 17:48:54', 1, 13),
(435, 435, 250, 0, '2017-08-31 00:00:00', '2017-09-05 17:50:51', 1, 13),
(436, 436, 3000, 0, '2017-09-03 00:00:00', '2017-09-05 17:52:03', 1, 13),
(437, 437, 400, 0, '2017-08-19 00:00:00', '2017-08-19 17:57:16', 1, 13),
(438, 438, 240, 0, '2017-08-19 00:00:00', '2017-08-19 18:01:17', 1, 13),
(439, 439, 100, 0, '2017-08-23 00:00:00', '2017-09-05 18:16:52', 1, 13),
(440, 440, 350, 0, '2017-08-19 00:00:00', '2017-09-05 18:20:35', 1, 13),
(441, 441, 500, 0, '2017-08-11 00:00:00', '2017-08-11 18:23:31', 1, 13),
(443, 443, 350, 0, '2017-09-07 00:00:00', '2017-09-07 09:39:27', 1, 3),
(444, 444, 150, 0, '2017-09-07 00:00:00', '2017-09-07 09:47:16', 1, 3),
(445, 445, 450, 0, '2017-09-07 00:00:00', '2017-09-07 09:56:01', 1, 3),
(446, 446, 500, 0, '2017-09-06 00:00:00', '2017-09-06 11:17:17', 1, 3),
(447, 447, 300, 0, '2017-09-08 00:00:00', '2017-09-08 13:43:24', 1, 3),
(448, 448, 200, 0, '2017-09-08 00:00:00', '2017-09-08 16:20:56', 1, 3),
(449, 449, 300, 0, '2017-09-08 00:00:00', '2017-09-08 17:39:37', 1, 13),
(452, 452, 400, 0, '2017-09-08 00:00:00', '2017-09-08 18:51:20', 1, 3),
(451, 451, 600, 0, '2017-09-07 00:00:00', '2017-09-07 12:35:02', 1, 3),
(453, 453, 280, 0, '2017-09-09 00:00:00', '2017-09-09 12:17:49', 1, 12),
(454, 454, 650, 0, '2017-09-09 00:00:00', '2017-09-09 12:23:01', 1, 12),
(455, 455, 1200, 0, '2017-09-09 00:00:00', '2017-09-09 13:01:16', 1, 12),
(456, 456, 1300, 0, '2017-09-09 00:00:00', '2017-09-09 13:09:55', 1, 12),
(457, 457, 500, 0, '2017-09-09 00:00:00', '2017-09-09 16:01:50', 1, 16),
(458, 458, 1000, 0, '2017-09-09 00:00:00', '2017-09-09 16:56:21', 1, 16),
(459, 459, 400, 0, '2017-09-11 00:00:00', '2017-09-11 09:37:03', 1, 3),
(460, 460, 700, 0, '2017-09-11 00:00:00', '2017-09-11 11:47:14', 1, 3),
(461, 461, 400, 0, '2017-09-11 00:00:00', '2017-09-11 14:11:43', 1, 3),
(462, 462, 250, 0, '2017-09-11 00:00:00', '2017-09-11 14:23:10', 1, 3),
(463, 463, 350, 0, '2017-09-11 00:00:00', '2017-09-11 14:41:56', 1, 3),
(464, 464, 180, 0, '2017-09-11 00:00:00', '2017-09-11 15:38:18', 1, 3),
(465, 465, 15000, 0, '2017-09-11 00:00:00', '2017-09-11 16:08:06', 1, 3),
(466, 466, 80, 0, '2017-09-11 00:00:00', '2017-09-11 20:04:42', 1, 3),
(467, 467, 60, 0, '2017-07-24 00:00:00', '2017-07-24 20:18:00', 1, 3),
(468, 468, 30, 0, '2017-06-21 00:00:00', '2017-06-21 20:19:52', 1, 3),
(469, 469, 100, 0, '2017-07-24 00:00:00', '2017-07-24 20:33:21', 1, 13),
(470, 470, 700, 0, '2017-09-12 00:00:00', '2017-09-12 10:49:00', 1, 3),
(471, 471, 300, 0, '2017-07-31 00:00:00', '2017-07-31 11:37:46', 1, 3),
(472, 472, 40, 0, '2017-09-12 00:00:00', '2017-09-12 11:43:00', 1, 3),
(473, 473, 350, 0, '2017-07-10 00:00:00', '2017-07-10 11:45:20', 1, 3),
(474, 474, 150, 0, '2017-07-31 00:00:00', '2017-07-31 11:58:17', 1, 3),
(475, 475, 1100, 0, '2017-03-17 00:00:00', '2017-03-17 12:00:32', 1, 3),
(476, 476, 300, 0, '2017-06-10 00:00:00', '2017-06-10 12:37:00', 1, 3),
(477, 477, 20, 0, '2017-09-12 13:34:36', '2017-09-12 13:34:36', 1, 9),
(478, 478, 100, 0, '2017-09-12 14:26:00', '2017-09-12 14:26:01', 1, 13),
(479, 479, 400, 0, '2017-09-12 18:07:59', '2017-09-12 18:07:59', 1, 3),
(480, 480, 12, 0, '2017-09-12 20:11:25', '2017-09-12 20:11:26', 1, 9),
(481, 481, 400, 0, '2017-08-07 11:09:06', '2017-09-13 11:09:06', 1, 3),
(482, 482, 150, 0, '2017-09-13 11:55:26', '2017-09-13 11:55:26', 1, 3),
(483, 483, 200, 0, '2017-09-11 18:43:38', '2017-09-13 18:43:39', 1, 3),
(484, 484, 250, 0, '2017-09-13 19:14:33', '2017-09-13 19:14:34', 1, 3),
(485, 485, 12000, 0, '2017-09-14 11:27:52', '2017-09-14 11:27:53', 1, 3),
(486, 486, 50, 0, '2017-09-14 12:02:40', '2017-09-14 12:02:41', 1, 3),
(487, 487, 400, 0, '2017-09-14 12:29:23', '2017-09-14 12:29:24', 1, 3),
(488, 488, 80, 0, '2017-09-14 12:38:27', '2017-09-14 12:38:28', 1, 3),
(489, 489, 500, 0, '2017-09-14 17:59:25', '2017-09-14 17:59:25', 1, 3),
(490, 490, 2000, 0, '2017-09-15 10:27:37', '2017-09-15 10:27:37', 1, 3),
(491, 491, 2000, 0, '2017-09-15 12:17:30', '2017-09-15 12:17:31', 1, 3),
(492, 492, 200, 0, '2017-09-15 15:55:38', '2017-09-15 15:55:38', 1, 13),
(493, 493, 400, 0, '2017-09-15 16:52:32', '2017-09-15 16:52:32', 1, 13),
(494, 494, 25000, 0, '2017-09-15 17:05:04', '2017-09-15 17:05:05', 1, 13),
(495, 495, 200, 0, '2017-09-15 19:48:55', '2017-09-15 19:48:55', 1, 13),
(496, 496, 400, 0, '2017-09-16 11:53:43', '2017-09-16 11:53:43', 1, 12),
(497, 497, 250, 0, '2017-09-16 12:33:40', '2017-09-16 12:33:39', 1, 12),
(498, 498, 550, 0, '2017-09-16 12:45:34', '2017-09-16 12:45:34', 1, 12),
(499, 499, 250, 0, '2017-09-16 12:54:26', '2017-09-16 12:54:25', 1, 12),
(500, 500, 450, 0, '2017-09-16 16:24:32', '2017-09-16 16:24:32', 1, 12),
(501, 501, 600, 0, '2017-09-16 18:06:03', '2017-09-16 18:06:04', 1, 13),
(502, 502, 250, 0, '2017-09-18 10:12:35', '2017-09-18 10:12:35', 1, 3),
(503, 503, 400, 0, '2017-09-18 11:17:18', '2017-09-18 11:17:18', 1, 3),
(504, 504, 800, 0, '2017-09-18 12:04:28', '2017-09-18 12:04:29', 1, 3),
(505, 505, 120, 0, '2017-09-18 12:21:35', '2017-09-18 12:21:35', 1, 3),
(506, 506, 150, 0, '2017-09-18 12:26:50', '2017-09-18 12:26:51', 1, 3),
(507, 507, 1000, 0, '2017-09-18 00:52:04', '2017-09-18 12:52:13', 1, 3),
(508, 508, 350, 0, '2017-09-18 02:45:47', '2017-09-18 14:45:56', 1, 3),
(509, 509, 200, 0, '2017-09-18 03:15:55', '2017-09-18 15:16:04', 1, 3),
(510, 510, 1000, 0, '2017-09-18 05:05:44', '2017-09-18 17:05:53', 1, 3),
(511, 511, 26, 0, '2017-09-18 23:49:57', '2017-09-18 23:50:00', 1, 9),
(512, 512, 150, 0, '2017-09-19 13:24:58', '2017-09-19 13:25:01', 1, 3),
(513, 513, 250, 0, '2017-09-19 14:13:11', '2017-09-19 14:13:12', 1, 3),
(514, 514, 1000, 0, '2017-09-19 15:43:26', '2017-09-19 15:43:27', 1, 3),
(515, 515, 350, 0, '2017-09-19 17:08:59', '2017-09-19 17:09:01', 1, 3),
(516, 516, 400, 0, '2017-09-19 19:48:11', '2017-09-19 19:48:17', 1, 8),
(517, 517, 3500, 0, '2017-09-20 09:50:38', '2017-09-20 09:50:40', 1, 3),
(518, 518, 200, 0, '2017-09-20 11:37:46', '2017-09-20 11:37:47', 1, 3),
(519, 519, 600, 0, '2017-09-20 11:57:50', '2017-09-20 11:57:51', 1, 3),
(520, 520, 100, 0, '2017-09-20 16:10:12', '2017-09-20 16:10:14', 1, 3),
(521, 521, 300, 0, '2017-09-20 16:17:30', '2017-09-20 16:17:32', 1, 3),
(522, 522, 300, 0, '2017-09-20 18:58:37', '2017-09-20 18:58:38', 1, 3),
(523, 523, 900, 0, '2017-09-21 10:25:37', '2017-09-21 10:25:38', 1, 3),
(524, 524, 170, 0, '2017-09-21 17:06:32', '2017-09-21 17:06:33', 1, 3),
(525, 525, 350, 0, '2017-09-21 18:02:25', '2017-09-21 18:02:27', 1, 3),
(526, 526, 250, 0, '2017-09-21 18:36:34', '2017-09-21 18:36:36', 1, 3),
(527, 527, 20, 0, '2017-09-22 09:14:46', '2017-09-22 09:14:48', 1, 13),
(528, 528, 50, 0, '2017-09-22 10:34:47', '2017-09-22 10:34:49', 1, 3),
(529, 529, 400, 0, '2017-09-22 14:27:27', '2017-09-22 14:27:30', 1, 3),
(530, 530, 100, 0, '2017-09-22 16:04:01', '2017-09-22 16:04:03', 1, 3),
(531, 531, 300, 0, '2017-09-22 16:31:27', '2017-09-22 16:31:29', 1, 3),
(532, 532, 60, 0, '2017-09-22 17:24:00', '2017-09-22 17:24:01', 1, 9),
(533, 533, 11, 0, '2017-09-22 18:02:09', '2017-09-22 18:02:09', 1, 1),
(534, 534, 40, 0, '2017-09-22 18:42:05', '2017-09-22 18:42:05', 1, 1),
(535, 535, 400, 0, '2017-09-22 18:42:28', '2017-09-22 18:42:29', 1, 13);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `DetalleReporte`
--

CREATE TABLE `DetalleReporte` (
  `idDetalleReporte` int(11) NOT NULL,
  `repoDescripcion` varchar(200) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `DetalleReporte`
--

INSERT INTO `DetalleReporte` (`idDetalleReporte`, `repoDescripcion`) VALUES
(1, 'Se canceló el interés'),
(2, 'Se hizo un adelanto'),
(3, 'Crédito finalizado'),
(4, 'Aún no hay ninguna confirmación'),
(5, '- Administrador, estado: Recogido'),
(6, '- Adminsitrador, estado: Rematar.'),
(9, 'Cancela capital y retiro'),
(7, '- Aceptó el movimiento'),
(8, 'Retiro de artículo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `PagoaCuenta`
--

CREATE TABLE `PagoaCuenta` (
  `idPago` int(11) NOT NULL,
  `idDesembolso` int(11) NOT NULL,
  `pagMonto` float NOT NULL,
  `pagInteres` float NOT NULL,
  `pagCantidadPagada` int(11) NOT NULL,
  `pagDebeInteres` float NOT NULL DEFAULT '0',
  `pagFechaRegistro` datetime NOT NULL,
  `idUsuario` int(11) NOT NULL,
  `idTipoPago` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `PagoaCuenta`
--

INSERT INTO `PagoaCuenta` (`idPago`, `idDesembolso`, `pagMonto`, `pagInteres`, `pagCantidadPagada`, `pagDebeInteres`, `pagFechaRegistro`, `idUsuario`, `idTipoPago`) VALUES
(1, 532, 60, 6.16, 66, 0, '2017-09-22 17:41:41', 9, 10),
(2, 532, 60, 6.16, 66, 0, '2017-09-22 17:41:41', 9, 13),
(3, 532, 60, 6.16, 66, 0, '2017-09-22 17:43:54', 9, 10),
(4, 532, 60, 6.16, 66, 0, '2017-09-22 17:43:54', 9, 13);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `poder`
--

CREATE TABLE `poder` (
  `idPoder` int(11) NOT NULL,
  `Descripcion` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `poder`
--

INSERT INTO `poder` (`idPoder`, `Descripcion`) VALUES
(1, 'Director operativo'),
(2, 'Colaborador administrativo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `prestamo`
--

CREATE TABLE `prestamo` (
  `idPrestamo` int(11) NOT NULL,
  `idProducto` int(11) NOT NULL,
  `idCliente` int(11) NOT NULL,
  `preCapital` float NOT NULL,
  `preFechaInicio` datetime NOT NULL,
  `idSucursal` int(11) NOT NULL,
  `idUsuario` int(11) NOT NULL,
  `presActivo` bit(1) NOT NULL,
  `presObservaciones` text NOT NULL,
  `preIdEstado` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `prestamo`
--

INSERT INTO `prestamo` (`idPrestamo`, `idProducto`, `idCliente`, `preCapital`, `preFechaInicio`, `idSucursal`, `idUsuario`, `presActivo`, `presObservaciones`, `preIdEstado`) VALUES
(1, 1, 1, 50, '2017-02-06 12:29:21', 1, 2, b'1', '', 1),
(2, 2, 2, 200, '2017-02-06 12:42:39', 1, 2, b'1', '', 1),
(3, 3, 3, 26, '2017-02-06 13:00:15', 1, 2, b'1', '', 1),
(4, 4, 4, 252, '2017-02-06 13:04:22', 1, 2, b'1', '', 1),
(5, 5, 5, 60, '2017-02-06 13:08:30', 1, 2, b'1', '', 1),
(6, 6, 6, 500, '2017-02-06 13:26:03', 1, 2, b'1', '', 1),
(7, 7, 7, 350, '2017-02-06 13:30:46', 1, 2, b'1', '', 1),
(8, 8, 8, 48, '2017-02-06 13:36:28', 1, 2, b'1', '', 1),
(9, 9, 9, 400, '2017-02-06 13:45:32', 1, 2, b'1', '', 1),
(10, 10, 10, 51.2, '2017-02-06 13:52:49', 1, 2, b'1', '', 1),
(11, 11, 11, 500, '2017-02-06 13:56:58', 1, 2, b'1', '', 1),
(12, 12, 12, 150, '2017-02-06 14:03:55', 1, 2, b'1', '', 1),
(13, 13, 13, 100, '2017-02-06 14:19:15', 1, 2, b'1', '', 1),
(14, 14, 14, 105, '2017-02-06 14:38:37', 1, 2, b'1', '', 1),
(15, 15, 15, 25.2, '2017-02-07 17:46:08', 1, 2, b'1', '', 1),
(16, 16, 16, 100, '2017-02-07 17:51:17', 1, 2, b'1', '', 1),
(17, 17, 17, 336, '2017-02-07 17:54:08', 1, 2, b'1', '', 1),
(18, 18, 18, 170, '2017-02-07 17:57:25', 1, 2, b'1', '', 1),
(19, 19, 19, 168, '2017-02-08 15:20:29', 1, 2, b'1', '', 1),
(20, 20, 20, 200, '2017-02-09 16:39:09', 1, 2, b'1', '', 1),
(21, 21, 15, 80, '2017-02-09 18:34:00', 1, 2, b'1', '', 1),
(22, 22, 21, 450, '2017-02-09 19:12:54', 1, 2, b'1', '', 1),
(23, 23, 22, 700, '2017-02-09 19:16:56', 1, 2, b'1', '', 1),
(51, 51, 50, 300, '2017-02-10 16:27:41', 1, 2, b'1', '', 1),
(26, 26, 25, 80, '2017-02-09 19:30:32', 1, 2, b'1', '', 1),
(27, 27, 26, 590, '2017-02-09 19:33:28', 1, 2, b'1', '', 1),
(28, 28, 27, 520, '2017-02-09 19:35:55', 1, 2, b'1', '', 1),
(29, 29, 28, 200, '2017-02-09 19:41:13', 1, 2, b'1', '', 1),
(30, 30, 29, 200, '2017-02-09 19:43:04', 1, 2, b'1', '', 1),
(31, 31, 30, 200, '2017-02-09 19:46:47', 1, 2, b'1', '', 1),
(32, 32, 31, 200, '2017-02-09 19:50:07', 1, 2, b'1', '', 1),
(33, 33, 32, 1000, '2017-02-09 19:52:48', 1, 2, b'1', '', 1),
(34, 34, 33, 150, '2017-02-09 19:54:32', 1, 2, b'1', '', 1),
(35, 35, 34, 70, '2017-02-09 19:56:18', 1, 2, b'1', '', 1),
(36, 36, 35, 100, '2017-02-09 19:58:05', 1, 2, b'1', '', 1),
(37, 37, 36, 500, '2017-02-09 19:59:57', 1, 2, b'1', '', 1),
(38, 38, 37, 60, '2017-02-09 20:01:48', 1, 2, b'1', '', 1),
(50, 50, 49, 600, '2017-02-10 16:25:09', 1, 2, b'1', '', 1),
(40, 40, 39, 350, '2017-02-09 20:05:36', 1, 2, b'1', '', 1),
(41, 41, 40, 80, '2017-02-09 20:07:48', 1, 2, b'1', '', 1),
(42, 42, 41, 68, '2017-02-09 20:09:44', 1, 2, b'1', '', 1),
(43, 43, 42, 550, '2017-02-09 20:11:52', 1, 2, b'1', '', 1),
(44, 44, 43, 400, '2017-02-09 20:13:30', 1, 2, b'1', '', 1),
(45, 45, 44, 180, '2017-02-09 20:15:14', 1, 2, b'1', '', 1),
(46, 46, 45, 60, '2017-02-09 20:17:13', 1, 2, b'1', '', 1),
(47, 47, 46, 800, '2017-02-09 20:19:06', 1, 2, b'1', '', 1),
(48, 48, 47, 500, '2017-02-09 20:20:40', 1, 2, b'1', '', 1),
(49, 49, 48, 500, '2017-02-10 12:33:53', 1, 2, b'1', '', 1),
(52, 52, 51, 300, '2017-02-10 16:47:31', 1, 2, b'1', '', 1),
(53, 53, 52, 60, '2017-02-10 18:18:09', 1, 2, b'1', '', 1),
(54, 54, 53, 80, '2017-02-11 12:10:09', 1, 2, b'1', '', 1),
(55, 55, 54, 19, '2017-02-13 12:43:31', 2, 9, b'0', '', 11),
(56, 56, 54, 160, '2017-02-13 12:44:43', 2, 9, b'0', '', 11),
(57, 57, 55, 50, '2017-02-13 15:32:14', 1, 2, b'1', '', 1),
(58, 58, 56, 700, '2017-02-13 16:03:28', 1, 2, b'1', '', 1),
(59, 59, 57, 170, '2017-02-13 16:34:48', 1, 2, b'1', '', 1),
(60, 60, 58, 300, '2017-02-13 17:27:00', 1, 2, b'1', '', 1),
(61, 61, 59, 300, '2017-02-13 17:49:57', 1, 2, b'1', '', 1),
(62, 62, 57, 107, '2017-02-13 19:00:44', 1, 2, b'1', '', 1),
(63, 63, 60, 100, '2017-02-14 11:06:32', 1, 2, b'1', '', 1),
(64, 64, 54, 140, '2017-02-14 14:05:50', 2, 9, b'0', '', 11),
(65, 65, 61, 100, '2017-02-14 14:31:23', 3, 10, b'1', '', 1),
(66, 66, 62, 80, '2017-02-15 13:30:53', 1, 2, b'1', '', 1),
(67, 67, 63, 40, '2017-02-16 13:58:46', 1, 2, b'1', '', 1),
(68, 68, 64, 200, '2017-02-20 10:27:08', 1, 2, b'1', '', 1),
(69, 69, 65, 100, '2017-02-20 12:20:53', 1, 2, b'1', '', 1),
(70, 70, 66, 101, '2017-02-20 12:57:52', 1, 2, b'1', '', 1),
(71, 71, 67, 100, '2017-02-20 14:08:25', 1, 2, b'1', '', 1),
(72, 72, 68, 500, '2017-02-21 09:52:04', 1, 2, b'1', '', 1),
(73, 73, 69, 100, '2017-02-22 16:50:08', 1, 2, b'1', '', 1),
(74, 74, 4, 1000, '2017-02-23 19:01:40', 1, 2, b'1', '', 1),
(75, 75, 70, 300, '2017-02-24 09:49:29', 1, 2, b'1', '', 1),
(76, 76, 71, 160, '2017-02-24 18:07:38', 1, 2, b'1', '', 1),
(77, 77, 72, 2000, '2017-02-24 19:26:10', 1, 2, b'1', '', 1),
(78, 78, 73, 2000, '2017-02-24 19:26:11', 1, 2, b'1', '', 1),
(79, 79, 65, 400, '2017-02-28 12:02:23', 1, 2, b'1', '', 1),
(80, 80, 74, 150, '2017-02-28 13:56:43', 1, 2, b'1', '', 1),
(81, 81, 75, 600, '2017-03-01 13:09:24', 1, 2, b'1', '', 1),
(82, 82, 76, 1500, '2017-03-02 17:55:57', 1, 2, b'1', '', 1),
(83, 83, 77, 300, '2017-03-04 12:37:50', 1, 2, b'1', '', 1),
(84, 84, 78, 300, '2017-03-04 13:31:52', 1, 2, b'1', '', 1),
(85, 85, 79, 400, '2017-03-06 11:56:47', 1, 2, b'1', '', 1),
(86, 86, 80, 1200, '2017-03-07 15:37:02', 1, 2, b'1', '', 1),
(87, 87, 81, 756, '2017-03-09 12:46:02', 1, 2, b'1', '', 1),
(88, 88, 82, 30, '2017-03-09 17:25:37', 1, 2, b'1', '', 1),
(89, 89, 83, 850, '2017-03-10 11:51:58', 1, 2, b'1', '', 1),
(90, 90, 84, 50, '2017-03-10 14:36:47', 1, 2, b'1', '', 1),
(91, 91, 85, 300, '2017-03-10 15:03:28', 1, 2, b'1', '', 1),
(92, 92, 86, 150, '2017-03-11 10:06:40', 1, 2, b'1', '', 1),
(93, 93, 87, 140, '2017-03-11 11:06:00', 1, 2, b'1', '', 1),
(94, 94, 88, 350, '2017-03-13 20:37:08', 1, 2, b'1', '', 1),
(95, 95, 89, 230, '2017-03-14 14:05:24', 1, 2, b'1', '', 1),
(96, 96, 90, 1100, '2017-03-17 13:13:35', 1, 2, b'1', '', 1),
(97, 97, 91, 500, '2017-03-17 14:00:39', 1, 2, b'1', '', 1),
(98, 98, 92, 400, '2017-03-18 13:03:20', 1, 2, b'1', '', 1),
(99, 99, 3, 150, '2017-03-20 15:47:54', 1, 2, b'1', '', 1),
(100, 100, 93, 1000, '2017-03-20 20:19:35', 1, 2, b'1', '', 1),
(101, 101, 94, 350, '2017-03-21 14:24:41', 1, 2, b'1', '', 1),
(102, 102, 95, 200, '2017-03-22 12:26:06', 1, 2, b'1', '', 1),
(103, 103, 96, 200, '2017-03-23 16:48:58', 1, 2, b'1', '', 1),
(104, 104, 97, 280, '2017-03-24 18:18:45', 1, 2, b'1', '', 1),
(105, 105, 75, 300, '2017-03-24 19:36:17', 1, 2, b'1', '', 1),
(106, 106, 98, 1200, '2017-03-25 16:09:31', 1, 2, b'1', '', 1),
(107, 107, 99, 130, '2017-03-28 11:39:31', 1, 2, b'1', '', 1),
(108, 108, 100, 200, '2017-03-28 13:39:52', 1, 2, b'1', '', 1),
(109, 109, 101, 70, '2017-03-28 17:17:27', 1, 2, b'1', '', 1),
(110, 110, 102, 2500, '2017-03-29 12:58:02', 1, 2, b'1', '', 1),
(111, 111, 103, 800, '2017-03-31 16:59:12', 1, 2, b'1', '', 1),
(112, 112, 104, 500, '2017-03-31 17:15:52', 1, 2, b'1', '', 1),
(113, 113, 105, 300, '2017-03-31 17:29:07', 1, 2, b'1', '', 1),
(114, 114, 106, 250, '2017-03-31 19:43:38', 1, 2, b'1', '', 1),
(115, 115, 70, 300, '2017-04-01 09:20:44', 1, 2, b'1', '', 1),
(116, 116, 107, 300, '2017-04-01 15:56:38', 1, 2, b'1', '', 1),
(117, 117, 107, 300, '2017-04-01 15:59:14', 1, 2, b'1', '', 1),
(118, 118, 108, 500, '2017-04-03 18:56:12', 1, 2, b'1', '', 1),
(119, 119, 102, 2500, '2017-04-04 17:20:33', 1, 2, b'1', '', 1),
(120, 120, 109, 600, '2017-04-05 13:02:52', 1, 2, b'1', '', 1),
(121, 121, 54, 80, '2017-04-05 16:57:12', 2, 9, b'1', '', 1),
(122, 122, 110, -666, '2017-04-07 10:14:24', 1, 2, b'1', '', 1),
(123, 123, 111, 70, '2017-04-07 12:12:28', 1, 2, b'1', '', 1),
(124, 124, 112, 250, '2017-04-07 12:38:52', 1, 2, b'1', '', 1),
(125, 125, 113, 350, '2017-04-09 14:03:07', 1, 2, b'1', '', 1),
(126, 126, 114, 150, '2017-04-10 17:44:43', 1, 2, b'1', '', 1),
(127, 127, 115, 64, '2017-04-10 18:37:40', 1, 2, b'1', '', 1),
(128, 128, 116, 0, '2017-04-11 10:27:05', 1, 2, b'1', '', 1),
(129, 129, 69, 200, '2017-04-11 10:50:20', 1, 2, b'1', '', 1),
(130, 130, 117, 40, '2017-04-11 11:07:14', 1, 2, b'1', '', 1),
(131, 131, 118, 1500, '2017-04-11 14:57:54', 1, 2, b'1', '', 1),
(132, 132, 119, 300, '2017-04-11 17:25:14', 1, 2, b'1', '', 1),
(133, 133, 120, 200, '2017-04-11 18:27:59', 1, 2, b'1', '', 1),
(134, 134, 121, 200, '2017-04-12 11:53:44', 1, 2, b'1', '', 1),
(135, 135, 122, 150, '2017-04-12 12:02:53', 1, 2, b'1', '', 1),
(136, 136, 123, 200, '2017-04-12 12:24:15', 1, 2, b'1', '', 1),
(137, 137, 124, 300, '2017-04-12 16:28:45', 1, 2, b'1', '', 1),
(138, 138, 125, 150, '2017-04-12 17:35:50', 1, 2, b'1', '', 1),
(139, 139, 126, 350, '2017-04-13 10:58:40', 1, 2, b'1', '', 1),
(140, 140, 54, 90, '2017-04-17 11:20:34', 2, 9, b'0', '', 11),
(141, 141, 54, 300, '2017-04-17 12:09:16', 2, 9, b'1', '', 1),
(142, 142, 127, 200, '2017-04-17 12:33:11', 2, 9, b'1', '', 1),
(143, 143, 128, 150, '2017-04-17 12:44:39', 1, 2, b'1', '', 1),
(144, 144, 129, 70, '2017-04-17 13:10:48', 1, 2, b'1', '', 1),
(145, 145, 130, 400, '2017-04-17 18:52:03', 1, 2, b'1', '', 1),
(146, 146, 95, 200, '2017-04-18 15:50:25', 1, 2, b'1', '', 1),
(147, 147, 131, 300, '2017-04-19 16:54:45', 1, 2, b'1', '', 1),
(148, 148, 132, 350, '2017-04-20 11:26:55', 1, 2, b'1', '', 1),
(149, 149, 133, 300, '2017-04-20 16:37:59', 1, 2, b'1', '', 1),
(150, 150, 134, 300, '2017-04-20 18:29:19', 1, 2, b'1', '', 1),
(151, 151, 116, 70, '2017-04-21 09:57:44', 1, 2, b'1', '', 1),
(152, 152, 109, 300, '2017-04-21 17:42:29', 1, 2, b'1', '', 1),
(153, 153, 135, 1700, '2017-04-22 12:33:52', 1, 2, b'1', '', 1),
(154, 154, 136, 150, '2017-04-24 14:03:59', 1, 2, b'1', '', 1),
(155, 155, 137, 200, '2017-04-26 16:42:52', 1, 2, b'1', '', 1),
(156, 156, 138, 300, '2017-04-27 09:54:04', 1, 2, b'1', '', 1),
(157, 157, 139, 240, '2017-04-27 10:01:44', 1, 2, b'1', '', 1),
(158, 158, 140, 50, '2017-04-27 12:06:04', 1, 2, b'1', '', 1),
(159, 159, 141, 90, '2017-04-27 17:09:21', 1, 2, b'1', '', 1),
(160, 160, 102, 4000, '2017-04-28 13:30:45', 1, 2, b'1', '', 1),
(161, 161, 142, 300, '2017-04-28 14:50:03', 1, 2, b'1', '', 1),
(162, 162, 143, 100, '2017-04-28 18:55:43', 1, 2, b'1', '', 1),
(163, 163, 144, 200, '2017-04-29 12:24:16', 1, 2, b'1', '', 1),
(164, 164, 70, 250, '2017-05-02 09:20:19', 1, 2, b'1', '', 1),
(165, 165, 145, -20, '2017-05-03 14:26:13', 1, 2, b'1', '', 1),
(166, 166, 54, 50, '2017-05-04 13:43:19', 2, 9, b'1', '', 1),
(167, 167, 54, 15, '2017-05-04 13:44:50', 2, 9, b'1', '', 1),
(168, 168, 146, 300, '2017-05-08 11:24:29', 1, 2, b'1', '', 1),
(169, 169, 147, 800, '2017-05-08 14:43:09', 1, 2, b'1', '', 1),
(170, 170, 148, 500, '2017-05-09 18:53:24', 1, 2, b'1', '', 1),
(171, 171, 149, 500, '2017-05-10 17:17:11', 1, 2, b'1', '', 1),
(172, 172, 54, 15, '2017-05-11 11:17:08', 2, 9, b'1', '', 1),
(173, 173, 150, 400, '2017-05-11 13:37:13', 1, 2, b'1', '', 1),
(174, 174, 151, 400, '2017-05-11 15:09:36', 1, 2, b'1', '', 1),
(175, 175, 54, 130, '2017-05-11 17:54:02', 2, 9, b'1', '', 1),
(176, 176, 54, 150, '2017-05-11 18:38:01', 2, 9, b'1', '', 1),
(177, 177, 102, 4500, '2017-05-12 14:55:11', 1, 2, b'1', '', 1),
(178, 178, 106, 170, '2017-05-12 16:58:56', 1, 2, b'1', '', 1),
(179, 179, 152, 250, '2017-05-12 17:32:41', 1, 2, b'1', '', 1),
(180, 180, 153, 100, '2017-05-12 18:10:03', 1, 2, b'1', '', 1),
(181, 181, 154, 350, '2017-05-13 12:56:26', 1, 2, b'1', '', 1),
(182, 182, 155, 300, '2017-05-15 09:44:20', 1, 2, b'1', '', 1),
(183, 183, 156, 400, '2017-05-15 12:25:44', 1, 2, b'1', '', 1),
(184, 184, 157, 300, '2017-05-15 17:26:59', 1, 2, b'1', '', 1),
(185, 185, 158, 200, '2017-05-16 14:44:46', 1, 3, b'1', '', 1),
(186, 186, 159, 60, '2017-05-17 18:28:56', 1, 3, b'1', '', 1),
(187, 187, 160, 600, '2017-05-18 15:35:53', 1, 2, b'1', '', 1),
(188, 188, 161, 200, '2017-05-18 16:05:05', 1, 2, b'1', '', 1),
(189, 189, 59, 250, '2017-05-19 11:30:52', 1, 3, b'1', '', 1),
(190, 190, 156, 300, '2017-05-19 12:49:21', 1, 3, b'1', '', 1),
(191, 191, 162, 300, '2017-05-19 14:15:00', 1, 3, b'1', '', 1),
(192, 192, 163, 2500, '2017-05-19 15:40:26', 1, 3, b'1', '', 1),
(193, 193, 164, 350, '2017-05-19 16:30:14', 1, 3, b'1', '', 1),
(194, 194, 91, 300, '2017-05-19 17:08:42', 1, 3, b'1', '', 1),
(195, 195, 165, 150, '2017-05-20 10:17:37', 1, 3, b'1', '', 1),
(196, 196, 166, 70, '2017-05-20 13:59:32', 1, 3, b'1', '', 1),
(197, 197, 143, 300, '2017-05-22 12:16:32', 1, 3, b'1', '', 1),
(198, 198, 102, 6000, '2017-05-22 16:39:56', 1, 3, b'1', '', 1),
(199, 199, 167, 1500, '2017-05-22 18:13:17', 1, 3, b'1', '', 1),
(200, 200, 168, 50, '2017-05-22 19:07:09', 1, 3, b'1', '', 1),
(201, 201, 169, 150, '2017-05-23 18:09:44', 1, 3, b'0', '', 11),
(202, 202, 170, 100, '2017-05-24 14:50:47', 1, 3, b'1', '', 1),
(203, 203, 171, 200, '2017-05-24 15:04:50', 1, 3, b'1', '', 1),
(204, 204, 149, 200, '2017-05-25 16:47:11', 1, 3, b'0', '', 11),
(205, 205, 172, 400, '2017-05-25 17:27:36', 1, 3, b'1', '', 1),
(206, 206, 173, 100, '2017-05-25 18:59:01', 1, 3, b'1', '', 1),
(207, 207, 156, 450, '2017-05-26 09:33:03', 1, 3, b'1', '', 1),
(208, 208, 174, 500, '2017-05-26 10:29:05', 1, 3, b'1', '', 1),
(209, 209, 175, 50, '2017-05-26 15:40:53', 1, 3, b'1', '', 1),
(210, 210, 54, 500, '2017-05-27 09:15:30', 2, 9, b'1', '', 1),
(211, 211, 176, 1000, '2017-05-29 11:56:44', 1, 3, b'1', '', 1),
(212, 212, 102, 6000, '2017-05-29 18:21:35', 1, 3, b'1', '', 1),
(213, 213, 177, 100, '2017-05-30 09:26:58', 1, 3, b'1', '', 1),
(214, 214, 178, 200, '2017-05-30 15:41:29', 1, 3, b'1', '', 1),
(215, 215, 179, 200, '2017-05-30 17:18:04', 1, 3, b'1', '', 1),
(216, 216, 106, 250, '2017-05-30 19:15:08', 1, 3, b'1', '', 1),
(217, 217, 180, 200, '2017-06-02 10:18:34', 1, 3, b'1', '', 1),
(218, 218, 68, 300, '2017-06-02 13:09:13', 1, 3, b'1', '', 1),
(219, 219, 181, 150, '2017-06-02 17:54:37', 1, 3, b'1', '', 1),
(220, 220, 182, 200, '2017-06-02 18:11:22', 1, 3, b'1', '', 1),
(221, 221, 183, 180, '2017-06-03 11:49:01', 1, 12, b'1', '', 1),
(222, 222, 104, 350, '2017-06-03 12:16:19', 1, 12, b'1', '', 1),
(223, 223, 184, 400, '2017-06-05 10:50:27', 1, 3, b'1', '', 1),
(224, 224, 185, 200, '2017-06-05 11:50:28', 1, 3, b'1', '', 1),
(225, 225, 186, 120, '2017-06-05 12:17:00', 1, 3, b'1', '', 1),
(226, 226, 187, 350, '2017-06-05 15:11:28', 1, 3, b'1', '', 1),
(227, 227, 188, 70, '2017-06-05 17:22:02', 1, 3, b'1', '', 1),
(228, 228, 189, 50, '2017-06-05 18:31:09', 1, 3, b'1', '', 1),
(229, 229, 190, 3200, '2017-06-05 18:47:18', 1, 3, b'1', '', 1),
(230, 230, 112, 150, '2017-06-06 14:24:55', 1, 3, b'1', '', 1),
(231, 231, 191, 300, '2017-06-06 16:05:21', 1, 3, b'1', '', 1),
(232, 232, 156, 450, '2017-06-07 18:04:01', 1, 3, b'1', '', 1),
(233, 233, 102, 8000, '2017-06-07 18:47:14', 1, 3, b'1', '', 1),
(234, 234, 102, 450, '2017-06-07 18:56:53', 1, 3, b'1', '', 1),
(235, 235, 192, 450, '2017-06-08 10:45:43', 1, 3, b'1', '', 1),
(236, 236, 192, 300, '2017-06-08 11:20:13', 1, 3, b'1', '', 1),
(237, 237, 193, 100, '2017-06-08 13:11:20', 1, 3, b'1', '', 1),
(238, 238, 194, 300, '2017-06-08 17:34:34', 1, 3, b'1', '', 1),
(239, 239, 195, 40, '2017-06-09 14:01:01', 1, 12, b'1', '', 1),
(240, 240, 196, 800, '2017-06-09 14:38:29', 1, 12, b'1', '', 1),
(241, 241, 197, 60, '2017-06-12 09:37:51', 1, 3, b'1', '', 1),
(242, 242, 188, 100, '2017-06-12 09:39:53', 1, 3, b'1', '', 1),
(243, 243, 198, 400, '2017-06-12 09:51:42', 1, 3, b'1', '', 1),
(244, 244, 197, 80, '2017-06-12 10:00:16', 1, 3, b'1', '', 1),
(245, 245, 190, 4100, '2017-06-12 18:52:55', 1, 3, b'1', '', 1),
(246, 246, 199, 170, '2017-06-13 10:43:05', 1, 3, b'1', '', 1),
(247, 247, 200, 150, '2017-06-13 11:02:18', 1, 3, b'1', '', 1),
(248, 248, 201, 50, '2017-06-13 16:25:50', 1, 3, b'1', '', 1),
(249, 249, 156, 450, '2017-06-13 18:31:21', 1, 3, b'1', '', 1),
(251, 251, 202, 4000, '2017-06-14 11:37:24', 1, 3, b'1', '', 1),
(252, 252, 195, 50, '2017-06-14 17:06:36', 1, 3, b'1', '', 1),
(253, 253, 106, 600, '2017-06-15 09:44:33', 1, 3, b'1', '', 1),
(254, 254, 203, 150, '2017-06-15 11:27:05', 1, 3, b'1', '', 1),
(255, 255, 204, 600, '2017-06-15 12:41:47', 1, 3, b'1', '', 1),
(256, 256, 205, 228, '2017-06-15 12:50:49', 1, 3, b'1', '', 1),
(257, 257, 206, 330, '2017-06-15 17:08:38', 1, 13, b'1', '', 1),
(258, 258, 207, 400, '2017-06-16 09:52:43', 1, 3, b'1', '', 1),
(259, 259, 146, 300, '2017-06-16 10:42:30', 1, 3, b'1', '', 1),
(260, 260, 48, 400, '2017-06-16 11:06:37', 1, 3, b'0', '', 11),
(261, 261, 208, 150, '2017-06-16 11:24:23', 1, 3, b'1', '', 1),
(262, 262, 209, 500, '2017-06-16 17:14:49', 1, 3, b'1', '', 1),
(263, 263, 210, 400, '2017-06-19 19:31:54', 1, 3, b'1', '', 1),
(264, 264, 211, 350, '2017-06-19 20:18:15', 1, 13, b'1', '', 1),
(265, 265, 156, 450, '2017-06-20 10:26:49', 1, 3, b'1', '', 1),
(266, 266, 212, 30, '2017-06-21 10:55:53', 1, 3, b'1', '', 1),
(267, 267, 54, 150, '2017-06-21 14:06:52', 2, 9, b'1', '', 1),
(268, 268, 54, 136, '2017-06-21 14:29:41', 2, 9, b'1', '', 1),
(269, 269, 54, 55, '2017-06-21 14:42:05', 2, 9, b'1', '', 1),
(270, 270, 54, 20, '2017-06-21 16:55:04', 2, 9, b'1', '', 1),
(271, 271, 54, 15, '2017-06-21 17:48:24', 2, 9, b'1', '', 1),
(272, 272, 213, 400, '2017-06-22 10:27:58', 1, 3, b'1', '', 1),
(273, 273, 214, 800, '2017-06-22 13:36:39', 1, 3, b'1', '', 1),
(274, 274, 187, 400, '2017-06-23 15:19:30', 1, 3, b'1', '', 1),
(275, 275, 215, 90, '2017-06-23 16:23:03', 1, 3, b'1', '', 1),
(276, 276, 216, 400, '2017-06-23 16:44:51', 1, 3, b'1', '', 1),
(277, 277, 182, 80, '2017-06-23 18:35:02', 1, 3, b'1', '', 1),
(278, 278, 202, 500, '2017-06-23 19:26:31', 1, 3, b'1', '', 1),
(279, 279, 217, 200, '2017-06-24 09:58:09', 1, 13, b'1', '', 1),
(280, 280, 218, 600, '2017-06-24 10:01:19', 1, 13, b'1', '', 1),
(281, 281, 219, 200, '2017-06-24 11:47:31', 1, 12, b'1', '', 1),
(282, 282, 156, 300, '2017-06-26 09:51:12', 1, 3, b'1', '', 1),
(283, 283, 188, 100, '2017-06-26 17:40:20', 1, 3, b'1', '', 1),
(284, 284, 170, 150, '2017-06-26 20:08:10', 1, 13, b'1', '', 1),
(285, 285, 220, 70, '2017-06-26 20:10:39', 1, 13, b'1', '', 1),
(286, 286, 221, 10000, '2017-06-27 13:25:31', 1, 3, b'1', '', 1),
(287, 287, 209, 100, '2017-06-28 16:09:58', 1, 3, b'1', '', 1),
(288, 288, 204, 600, '2017-06-28 17:44:34', 1, 3, b'1', '', 1),
(289, 289, 222, 250, '2017-06-30 15:48:40', 1, 13, b'1', '', 1),
(290, 290, 223, 210, '2017-06-30 15:50:59', 1, 13, b'1', '', 1),
(291, 291, 224, 250, '2017-06-30 17:31:11', 1, 3, b'1', '', 1),
(292, 292, 225, 1300, '2017-06-30 18:18:37', 1, 3, b'1', '', 1),
(293, 293, 226, 2000, '2017-06-30 19:37:53', 1, 3, b'1', '', 1),
(294, 294, 227, 250, '2017-07-01 13:39:02', 1, 12, b'1', '', 1),
(295, 295, 228, 220, '2017-07-01 14:23:38', 1, 12, b'1', '', 1),
(296, 296, 229, 350, '2017-07-03 10:57:34', 1, 3, b'1', '', 1),
(297, 297, 230, 150, '2017-07-03 14:41:54', 1, 3, b'1', '', 1),
(298, 298, 102, 600, '2017-07-03 16:40:03', 1, 3, b'1', '', 1),
(299, 299, 54, 443, '2017-07-03 19:18:29', 2, 9, b'1', '', 1),
(300, 300, 156, 750, '2017-07-04 09:58:39', 1, 3, b'1', '', 1),
(301, 301, 231, 200, '2017-07-04 11:54:25', 1, 3, b'1', '', 1),
(302, 302, 232, 60, '2017-07-04 12:20:12', 1, 13, b'1', '', 1),
(303, 303, 233, 1300, '2017-07-04 12:23:30', 1, 13, b'1', '', 1),
(304, 304, 234, 150, '2017-07-04 18:12:36', 1, 3, b'1', '', 1),
(305, 305, 235, 700, '2017-07-05 17:43:32', 1, 3, b'1', '', 1),
(306, 306, 236, 200, '2017-07-05 21:09:13', 1, 13, b'1', '', 1),
(307, 307, 237, 230, '2017-07-05 21:11:58', 1, 13, b'1', '', 1),
(308, 308, 54, 500, '2017-07-07 12:09:14', 2, 9, b'1', '', 1),
(309, 309, 238, 104.4, '2017-07-07 14:07:54', 1, 14, b'1', '', 1),
(310, 310, 121, 280, '2017-07-08 12:33:01', 1, 12, b'1', '', 1),
(311, 311, 156, 450, '2017-07-10 10:39:28', 1, 3, b'1', '', 1),
(312, 312, 239, 40, '2017-07-10 10:49:27', 1, 3, b'1', '', 1),
(313, 313, 240, 1000, '2017-07-11 11:24:29', 3, 8, b'1', '', 1),
(314, 314, 241, 80, '2017-07-12 14:39:33', 1, 3, b'1', '', 1),
(315, 315, 191, 500, '2017-07-12 16:32:33', 1, 3, b'1', '', 1),
(316, 316, 54, 150, '2017-07-12 17:05:02', 2, 9, b'0', '', 11),
(317, 317, 54, 120, '2017-07-12 18:45:48', 2, 9, b'1', '', 1),
(318, 318, 206, 400, '2017-07-14 15:04:12', 1, 3, b'1', '', 1),
(319, 319, 242, 70, '2017-07-15 11:28:41', 1, 12, b'1', '', 1),
(320, 320, 213, 500, '2017-07-17 11:58:58', 1, 13, b'1', '', 1),
(321, 321, 188, 200, '2017-07-17 20:10:07', 1, 3, b'1', '', 1),
(322, 322, 242, 100, '2017-07-18 19:35:23', 1, 3, b'1', '', 1),
(323, 323, 47, 300, '2017-07-19 10:35:59', 1, 3, b'1', '', 1),
(324, 324, 243, 200, '2017-07-19 17:52:26', 1, 3, b'1', '', 1),
(325, 325, 244, 40, '2017-07-19 18:09:41', 1, 3, b'1', '', 1),
(326, 326, 245, 70, '2017-07-20 18:27:51', 1, 3, b'1', '', 1),
(327, 327, 246, 400, '2017-07-20 18:51:17', 1, 3, b'1', '', 1),
(328, 328, 247, 130, '2017-07-21 13:30:52', 1, 3, b'1', '', 1),
(329, 329, 248, 120, '2017-07-22 12:48:51', 1, 12, b'1', '', 1),
(330, 330, 54, 200, '2017-07-22 13:51:53', 2, 9, b'1', '', 1),
(331, 331, 59, 80, '2017-07-25 10:55:41', 1, 3, b'1', '', 1),
(332, 332, 249, 150, '2017-07-25 12:38:31', 1, 3, b'1', '', 1),
(333, 333, 250, 150, '2017-07-28 11:00:37', 1, 3, b'1', '', 1),
(334, 334, 251, 200, '2017-07-28 11:28:13', 1, 3, b'1', '', 1),
(335, 335, 252, 250, '2017-07-28 16:03:03', 1, 3, b'1', '', 1),
(336, 336, 227, 250, '2017-07-28 18:09:42', 1, 3, b'1', '', 1),
(337, 337, 253, 50, '2017-07-29 11:03:31', 1, 13, b'1', '', 1),
(338, 338, 254, 380, '2017-07-29 11:04:44', 1, 13, b'1', '', 1),
(339, 339, 255, 180, '2017-07-29 11:09:32', 1, 13, b'1', '', 1),
(340, 340, 256, 1000, '2017-07-29 11:12:43', 1, 13, b'1', '', 1),
(341, 341, 257, 200, '2017-07-29 11:16:28', 1, 13, b'1', '', 1),
(342, 342, 15, 40, '2017-07-29 11:18:55', 1, 13, b'1', '', 1),
(343, 343, 16, 80, '2017-07-29 11:26:20', 1, 13, b'1', '', 1),
(344, 344, 250, 300, '2017-07-29 11:33:15', 1, 13, b'1', '', 1),
(345, 345, 258, 15000, '2017-07-31 14:05:52', 1, 3, b'1', '', 1),
(346, 346, 259, 150, '2017-08-01 17:45:39', 1, 3, b'1', '', 1),
(347, 347, 251, 150, '2017-08-02 12:21:30', 1, 3, b'1', '', 1),
(348, 348, 260, 150, '2017-08-02 17:02:07', 1, 3, b'1', '', 1),
(349, 349, 261, 170, '2017-08-02 19:14:08', 1, 3, b'1', '', 1),
(350, 350, 262, 400, '2017-08-03 16:38:57', 1, 3, b'1', '', 1),
(351, 351, 118, 2000, '2017-08-03 18:08:52', 1, 3, b'1', '', 1),
(352, 352, 224, 250, '2017-08-07 17:40:34', 1, 3, b'1', '', 1),
(353, 353, 263, 1200, '2017-08-07 17:53:56', 1, 3, b'1', '', 1),
(354, 354, 250, 300, '2017-08-07 18:31:49', 1, 3, b'1', '', 1),
(355, 355, 264, 500, '2017-08-08 15:05:42', 1, 3, b'1', '', 1),
(356, 356, 227, 250, '2017-08-08 15:18:49', 1, 3, b'1', '', 1),
(357, 357, 265, 8000, '2017-08-08 15:29:28', 1, 3, b'1', '', 1),
(358, 358, 266, 250, '2017-08-08 17:45:03', 1, 3, b'1', '', 1),
(359, 359, 119, 250, '2017-08-09 16:26:11', 1, 3, b'1', '', 1),
(360, 360, 156, 50, '2017-08-10 10:36:23', 1, 3, b'1', '', 1),
(361, 361, 267, 5000, '2017-08-11 12:06:58', 1, 3, b'1', '', 1),
(362, 362, 198, 400, '2017-08-14 15:55:20', 1, 3, b'1', '', 1),
(363, 363, 268, 1000, '2017-08-14 18:22:36', 1, 13, b'1', '', 1),
(364, 364, 115, 600, '2017-08-14 18:24:19', 1, 13, b'1', '', 1),
(365, 365, 250, 200, '2017-08-15 10:13:33', 1, 3, b'1', '', 1),
(366, 366, 269, 80, '2017-08-15 10:52:12', 1, 3, b'1', '', 1),
(367, 367, 270, 60, '2017-08-15 11:59:05', 1, 3, b'1', '', 1),
(368, 368, 265, 2000, '2017-08-15 12:18:41', 1, 3, b'1', '', 1),
(369, 369, 271, 5000, '2017-08-15 16:11:33', 1, 3, b'1', '', 1),
(370, 370, 272, 250, '2017-08-16 10:13:16', 1, 3, b'1', '', 1),
(371, 371, 273, 1000, '2017-08-16 10:36:17', 1, 3, b'1', '', 1),
(372, 372, 274, 450, '2017-08-16 18:42:56', 1, 3, b'1', '', 1),
(373, 373, 69, 100, '2017-08-17 10:20:23', 1, 3, b'1', '', 1),
(374, 374, 275, 50, '2017-08-17 11:17:23', 1, 3, b'1', '', 1),
(375, 375, 276, 150, '2017-08-17 12:25:59', 1, 3, b'1', '', 1),
(376, 376, 277, 250, '2017-08-17 15:50:03', 1, 3, b'1', '', 1),
(377, 377, 278, 40, '2017-08-17 19:18:29', 1, 3, b'1', '', 1),
(378, 378, 279, 500, '2017-08-18 18:01:11', 1, 3, b'1', '', 1),
(379, 379, 280, 300, '2017-08-19 09:54:07', 1, 12, b'1', '', 1),
(380, 380, 281, 30, '2017-08-19 11:52:03', 1, 12, b'1', '', 1),
(381, 381, 282, 200, '2017-08-21 16:35:37', 1, 3, b'1', '', 1),
(382, 382, 283, 500, '2017-08-21 16:39:58', 1, 3, b'1', '', 1),
(383, 383, 284, 500, '2017-08-21 16:53:39', 1, 3, b'1', '', 1),
(384, 384, 285, 700, '2017-08-21 17:35:54', 1, 3, b'1', '', 1),
(385, 385, 250, 250, '2017-08-21 19:07:43', 1, 3, b'1', '', 1),
(386, 386, 286, 850, '2017-08-21 19:14:23', 1, 3, b'1', '', 1),
(387, 387, 287, 850, '2017-08-21 19:14:27', 1, 3, b'1', '', 1),
(388, 388, 288, 450, '2017-08-22 10:19:04', 1, 3, b'1', '', 1),
(389, 389, 289, 3000, '2017-08-22 11:43:13', 1, 3, b'1', '', 1),
(390, 390, 290, 150, '2017-08-23 12:43:00', 1, 3, b'1', '', 1),
(391, 391, 291, 750, '2017-08-23 18:54:11', 1, 3, b'1', '', 1),
(392, 392, 292, 100, '2017-08-24 10:16:09', 1, 3, b'1', '', 1),
(393, 393, 293, 600, '2017-08-24 11:54:18', 1, 3, b'1', '', 1),
(394, 394, 288, 550, '2017-08-24 12:04:23', 1, 3, b'1', '', 1),
(395, 395, 250, 400, '2017-08-24 14:10:18', 1, 3, b'1', '', 1),
(396, 396, 294, 350, '2017-08-24 16:34:48', 1, 3, b'1', '', 1),
(397, 397, 240, 1000, '2017-08-25 09:35:04', 1, 8, b'1', '', 1),
(398, 398, 295, 1000, '2017-08-25 13:14:57', 1, 3, b'1', '', 1),
(399, 399, 296, 400, '2017-08-25 15:00:09', 1, 3, b'1', '', 1),
(400, 400, 297, 1000, '2017-08-25 16:49:25', 1, 3, b'1', '', 1),
(401, 401, 298, 100, '2017-08-25 18:57:06', 1, 3, b'1', '', 1),
(402, 402, 299, 300, '2017-08-25 19:00:25', 1, 3, b'1', '', 1),
(403, 403, 300, 300, '2017-08-25 19:09:52', 1, 3, b'1', '', 1),
(404, 404, 301, 200, '2017-08-25 19:19:29', 1, 3, b'1', '', 1),
(405, 405, 302, 500, '2017-08-28 09:46:35', 1, 3, b'1', '', 1),
(406, 406, 303, 18000, '2017-08-28 10:01:22', 1, 3, b'1', '', 1),
(407, 407, 304, 700, '2017-08-28 12:06:25', 1, 13, b'1', '', 1),
(408, 408, 250, 150, '2017-08-28 12:09:27', 1, 13, b'1', '', 1),
(409, 409, 305, 100, '2017-08-29 10:51:28', 1, 3, b'1', '', 1),
(410, 410, 306, 100, '2017-08-29 10:58:57', 1, 3, b'1', '', 1),
(411, 411, 307, 200, '2017-08-29 11:18:14', 1, 3, b'1', '', 1),
(412, 412, 308, 70, '2017-08-29 13:49:46', 1, 3, b'1', '', 1),
(413, 413, 309, 300, '2017-08-30 10:04:15', 1, 3, b'1', '', 1),
(414, 414, 310, 80, '2017-08-30 18:51:21', 1, 3, b'1', '', 1),
(415, 415, 311, 300, '2017-08-31 10:48:37', 1, 3, b'1', '', 1),
(416, 416, 54, 100, '2017-08-31 16:51:37', 2, 9, b'1', '', 1),
(417, 417, 312, 900, '2017-09-01 10:40:28', 1, 3, b'1', '', 1),
(418, 418, 313, 150, '2017-09-01 12:18:25', 1, 3, b'1', '', 1),
(419, 419, 252, 300, '2017-09-01 16:01:19', 1, 3, b'1', '', 1),
(420, 420, 314, 700, '2017-09-01 18:11:15', 1, 3, b'1', '', 1),
(421, 421, 268, 1500, '2017-09-02 12:54:57', 1, 12, b'1', '', 1),
(422, 422, 156, 450, '2017-09-04 10:26:13', 1, 3, b'1', '', 1),
(423, 423, 315, 1000, '2017-09-04 15:43:19', 1, 3, b'1', '', 1),
(424, 424, 316, 1000, '2017-09-04 17:43:38', 1, 3, b'1', '', 1),
(425, 425, 317, 3000, '2017-09-04 18:01:29', 1, 13, b'1', '', 1),
(426, 426, 299, 1500, '2017-09-04 18:53:34', 1, 3, b'1', '', 1),
(427, 427, 156, 150, '2017-09-05 12:54:50', 1, 3, b'1', '', 1),
(428, 428, 318, 500, '2017-09-05 15:08:06', 1, 3, b'1', '', 1),
(429, 429, 319, 100, '2017-09-05 17:39:07', 1, 13, b'1', '', 1),
(430, 430, 319, 100, '2017-09-05 17:40:14', 1, 13, b'1', '', 1),
(442, 442, 326, 500, '2017-09-05 19:45:17', 1, 3, b'1', '', 1),
(433, 433, 288, 350, '2017-08-17 17:46:13', 1, 13, b'1', '', 1),
(434, 434, 312, 900, '2017-09-05 17:48:54', 1, 13, b'1', '', 1),
(435, 435, 251, 250, '2017-09-05 17:50:51', 1, 13, b'1', '', 1),
(436, 436, 317, 3000, '2017-09-05 17:52:03', 1, 13, b'1', '', 1),
(437, 437, 321, 400, '2017-08-19 17:57:16', 1, 13, b'1', '', 1),
(438, 438, 322, 240, '2017-08-19 18:01:17', 1, 13, b'1', '', 1),
(439, 439, 323, 100, '2017-09-05 18:16:52', 1, 13, b'1', '', 1),
(440, 440, 324, 350, '2017-09-05 18:20:35', 1, 13, b'1', '', 1),
(441, 441, 325, 500, '2017-08-11 18:23:31', 1, 13, b'1', '', 1),
(443, 443, 327, 350, '2017-09-07 09:39:27', 1, 3, b'1', '', 1),
(444, 444, 328, 150, '2017-09-07 09:47:16', 1, 3, b'1', '', 1),
(445, 445, 250, 450, '2017-09-07 09:56:01', 1, 3, b'1', '', 1),
(446, 446, 329, 500, '2017-09-06 11:17:17', 1, 3, b'1', '', 1),
(447, 447, 332, 300, '2017-09-08 13:43:24', 1, 3, b'1', '', 1),
(448, 448, 250, 200, '2017-09-08 16:20:56', 1, 3, b'1', '', 1),
(449, 449, 333, 300, '2017-09-08 17:39:37', 1, 13, b'1', '', 1),
(452, 452, 334, 400, '2017-09-08 18:51:20', 1, 3, b'1', '', 1),
(451, 451, 331, 600, '2017-09-07 12:35:02', 1, 3, b'1', '', 1),
(453, 453, 335, 280, '2017-09-09 12:17:49', 1, 12, b'1', '', 1),
(454, 454, 318, 650, '2017-09-09 12:23:01', 1, 12, b'1', '', 1),
(455, 455, 336, 1200, '2017-09-09 13:01:16', 1, 12, b'1', '', 1),
(456, 456, 336, 1300, '2017-09-09 13:09:55', 1, 12, b'1', '', 1),
(457, 457, 337, 500, '2017-09-09 16:01:50', 1, 16, b'1', '', 1),
(458, 458, 268, 1000, '2017-09-09 16:56:21', 1, 16, b'1', '', 1),
(459, 459, 333, 400, '2017-09-11 09:37:03', 1, 3, b'1', '', 1),
(460, 460, 338, 700, '2017-09-11 11:47:14', 1, 3, b'1', '', 1),
(461, 461, 150, 400, '2017-09-11 14:11:43', 1, 3, b'1', '', 1),
(462, 462, 339, 250, '2017-09-11 14:23:10', 1, 3, b'1', '', 1),
(463, 463, 85, 350, '2017-09-11 14:41:56', 1, 3, b'1', '', 1),
(464, 464, 12, 180, '2017-09-11 15:38:18', 1, 3, b'1', '', 1),
(465, 465, 340, 15000, '2017-09-11 16:08:06', 1, 3, b'1', '', 1),
(466, 466, 341, 80, '2017-09-11 20:04:42', 1, 3, b'1', '', 1),
(467, 467, 342, 60, '2017-07-24 20:18:00', 1, 3, b'1', '', 1),
(468, 468, 212, 30, '2017-06-21 20:19:52', 1, 3, b'1', '', 1),
(469, 469, 343, 100, '2017-07-24 20:33:21', 1, 13, b'1', '', 1),
(470, 470, 275, 700, '2017-09-12 10:49:00', 1, 3, b'1', '', 1),
(471, 471, 344, 300, '2017-07-31 11:37:46', 1, 3, b'1', '', 1),
(472, 472, 345, 40, '2017-09-12 11:43:00', 1, 3, b'1', '', 1),
(473, 473, 346, 350, '2017-07-10 11:45:20', 1, 3, b'1', '', 1),
(474, 474, 15, 150, '2017-07-31 11:58:17', 1, 3, b'1', '', 1),
(475, 475, 90, 1100, '2017-03-17 12:00:32', 1, 3, b'1', '', 1),
(476, 476, 347, 300, '2017-06-10 12:37:00', 1, 3, b'1', '', 1),
(477, 477, 348, 20, '2017-09-12 13:34:36', 2, 9, b'1', '', 1),
(478, 478, 349, 100, '2017-09-12 14:26:00', 1, 13, b'1', '', 1),
(479, 479, 350, 400, '2017-09-12 18:07:59', 1, 3, b'1', '', 1),
(480, 480, 54, 12, '2017-09-12 20:11:25', 2, 9, b'1', '', 1),
(481, 481, 184, 400, '2017-08-07 11:09:06', 1, 3, b'1', '', 1),
(482, 482, 351, 150, '2017-09-13 11:55:26', 1, 3, b'1', '', 1),
(483, 485, 352, 200, '2017-09-11 18:43:38', 1, 3, b'1', '', 1),
(484, 486, 353, 250, '2017-09-13 19:14:33', 1, 3, b'1', '', 1),
(485, 487, 265, 12000, '2017-09-14 11:27:52', 1, 3, b'1', '', 1),
(486, 488, 354, 50, '2017-09-14 12:02:40', 1, 3, b'1', '', 1),
(487, 489, 355, 400, '2017-09-14 12:29:23', 1, 3, b'1', '', 1),
(488, 490, 181, 80, '2017-09-14 12:38:27', 1, 3, b'1', '', 1),
(489, 491, 356, 500, '2017-09-14 17:59:25', 1, 3, b'1', '', 1),
(490, 492, 317, 2000, '2017-09-15 10:27:37', 1, 3, b'1', '', 1),
(491, 493, 357, 2000, '2017-09-15 12:17:30', 1, 3, b'1', '', 1),
(492, 494, 351, 200, '2017-09-15 15:55:38', 1, 13, b'1', '', 1),
(493, 495, 358, 400, '2017-09-15 16:52:32', 1, 13, b'1', '', 1),
(494, 496, 359, 25000, '2017-09-15 17:05:04', 1, 13, b'1', '', 1),
(495, 497, 156, 200, '2017-09-15 19:48:55', 1, 13, b'1', '', 1),
(496, 498, 250, 400, '2017-09-16 11:53:43', 1, 12, b'1', '', 1),
(497, 499, 360, 250, '2017-09-16 12:33:40', 1, 12, b'1', '', 1),
(498, 500, 361, 550, '2017-09-16 12:45:34', 1, 12, b'1', '', 1),
(499, 501, 71, 250, '2017-09-16 12:54:26', 1, 12, b'1', '', 1),
(500, 502, 362, 450, '2017-09-16 16:24:32', 1, 12, b'1', '', 1),
(501, 503, 363, 600, '2017-09-16 18:06:03', 1, 13, b'1', '', 1),
(502, 504, 250, 250, '2017-09-18 10:12:35', 1, 3, b'1', '', 1),
(503, 505, 113, 400, '2017-09-18 11:17:18', 1, 3, b'1', '', 1),
(504, 506, 364, 800, '2017-09-18 12:04:28', 1, 3, b'1', '', 1),
(505, 507, 365, 120, '2017-09-18 12:21:35', 1, 3, b'1', '', 1),
(506, 508, 305, 150, '2017-09-18 12:26:50', 1, 3, b'1', '', 1),
(507, 509, 366, 1000, '2017-09-18 00:52:04', 1, 3, b'1', '', 1),
(508, 510, 367, 350, '2017-09-18 02:45:47', 1, 3, b'1', '', 1),
(509, 511, 156, 200, '2017-09-18 03:15:55', 1, 3, b'1', '', 1),
(510, 512, 368, 1000, '2017-09-18 05:05:44', 1, 3, b'1', '', 1),
(511, 513, 54, 26, '2017-09-18 23:49:57', 2, 9, b'1', '', 1),
(512, 514, 369, 150, '2017-09-19 13:24:58', 1, 3, b'1', '', 1),
(513, 515, 370, 250, '2017-09-19 14:13:11', 1, 3, b'1', '', 1),
(514, 516, 371, 1000, '2017-09-19 15:43:26', 1, 3, b'1', '', 1),
(515, 517, 372, 350, '2017-09-19 17:08:59', 1, 3, b'1', '', 1),
(516, 518, 206, 400, '2017-09-19 19:48:11', 1, 8, b'1', '', 1),
(517, 519, 373, 3500, '2017-09-20 09:50:38', 1, 3, b'1', '', 1),
(518, 520, 374, 200, '2017-09-20 11:37:46', 1, 3, b'1', '', 1),
(519, 521, 375, 600, '2017-09-20 11:57:50', 1, 3, b'1', '', 1),
(520, 522, 180, 100, '2017-09-20 16:10:12', 1, 3, b'1', '', 1),
(521, 523, 376, 300, '2017-09-20 16:17:30', 1, 3, b'1', '', 1),
(522, 524, 377, 300, '2017-09-20 18:58:37', 1, 3, b'1', '', 1),
(523, 525, 378, 900, '2017-09-21 10:25:37', 1, 3, b'1', '', 1),
(524, 526, 47, 170, '2017-09-21 17:06:32', 1, 3, b'1', '', 1),
(525, 527, 379, 350, '2017-09-21 18:02:25', 1, 3, b'1', '', 1),
(526, 528, 106, 250, '2017-09-21 18:36:34', 1, 3, b'1', '', 1),
(527, 529, 380, 20, '2017-09-22 09:14:46', 1, 13, b'1', '', 1),
(528, 530, 156, 50, '2017-09-22 10:34:47', 1, 3, b'1', '', 1),
(529, 531, 381, 400, '2017-09-22 14:27:27', 1, 3, b'1', '', 1),
(530, 532, 382, 100, '2017-09-22 16:04:01', 1, 3, b'1', '', 1),
(531, 533, 383, 300, '2017-09-22 16:31:27', 1, 3, b'1', '', 1),
(532, 535, 54, 60, '2017-09-22 17:24:00', 2, 9, b'0', '', 11),
(533, 536, 54, 11, '2017-09-22 18:02:09', 1, 1, b'1', '', 1),
(534, 537, 54, 40, '2017-09-22 18:42:05', 1, 1, b'0', '', 11),
(535, 538, 385, 400, '2017-09-22 18:42:28', 1, 13, b'1', '', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `idProducto` int(11) NOT NULL,
  `prodNombre` varchar(200) NOT NULL,
  `prodMontoEntregado` float NOT NULL,
  `prodInteres` int(11) NOT NULL,
  `prodFechaInicial` date NOT NULL,
  `prodFechaVencimiento` date NOT NULL,
  `prodObservaciones` text NOT NULL,
  `prodMontoPagar` float NOT NULL,
  `prodAdelanto` float NOT NULL DEFAULT '0',
  `idCliente` int(11) NOT NULL,
  `prodDioAdelanto` bit(1) NOT NULL DEFAULT b'0',
  `prodActivo` bit(1) NOT NULL,
  `prodFechaRegistro` datetime DEFAULT NULL,
  `idUsuario` int(11) NOT NULL,
  `idSucursal` int(11) NOT NULL,
  `prodUltimaFechaInteres` varchar(100) NOT NULL DEFAULT '',
  `prodCuantoFinaliza` float NOT NULL DEFAULT '0',
  `prodQuienFinaliza` varchar(50) NOT NULL DEFAULT '',
  `prodFechaFinaliza` varchar(200) NOT NULL DEFAULT '',
  `prodAprobado` bit(1) NOT NULL DEFAULT b'0',
  `prodQuienAprueba` varchar(50) NOT NULL DEFAULT '',
  `esCompra` bit(1) NOT NULL DEFAULT b'0' COMMENT '1 para compra si, 0 para no'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`idProducto`, `prodNombre`, `prodMontoEntregado`, `prodInteres`, `prodFechaInicial`, `prodFechaVencimiento`, `prodObservaciones`, `prodMontoPagar`, `prodAdelanto`, `idCliente`, `prodDioAdelanto`, `prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal`, `prodUltimaFechaInteres`, `prodCuantoFinaliza`, `prodQuienFinaliza`, `prodFechaFinaliza`, `prodAprobado`, `prodQuienAprueba`, `esCompra`) VALUES
(1, 'tripode (hansa)', 50, 4, '2017-01-07', '2017-02-07', '', 60, 0, 1, b'0', b'0', '2017-02-06 12:29:21', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(2, 'camara panasonic con cargador + calular huawei cun-lo3', 200, 4, '2017-01-13', '2017-02-07', '', 232, 0, 2, b'0', b'0', '2017-02-06 12:42:39', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(3, 'laptop hp 455', 26, 4, '2017-02-16', '2017-02-18', 'Se adelantó S/. 20.80 de S/. 46.80 el día 16/02/2017<br>Se adelantó S/. 20.80 de S/. 67.60 el día 16/02/2017<br>Se adelantó S/. 20.80 de S/. 88.40 el día 16/02/2017<br>Se adelantó S/. 20.80 de S/. 109.20 el día 16/02/2017<br>Se adelantó S/. 20.80 de S/. 130.00 el día 16/02/2017<br>', 156, 0, 3, b'0', b'0', '2017-02-06 13:00:15', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(4, 'monitor led de 20\" + aspiradora vlast pro', 252, 4, '2017-02-23', '2017-02-18', 'Se adelantó S/. 48.00 de S/. 300.00 el día 23/02/2017<br>', 360, 0, 4, b'0', b'0', '2017-02-06 13:04:22', 2, 1, '', 413.28, 'Yuri Paola', '2017-06-14 18:54:58', b'0', '0', b'0'),
(5, 'monitor lG flatron 17\"', 60, 4, '2017-01-19', '2017-02-19', '', 72, 0, 5, b'0', b'0', '2017-02-06 13:08:30', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(6, 'cocina 5 hornillas bosh + blueray philips ', 500, 4, '2017-01-19', '2017-02-19', '', 600, 0, 6, b'0', b'0', '2017-02-06 13:26:03', 2, 1, '', 900, 'manrique', '2017-06-05 21:14:31', b'0', '0', b'0'),
(7, 'laptop hp pavilion ', 350, 4, '2017-01-20', '2017-02-20', '', 420, 0, 7, b'0', b'0', '2017-02-06 13:30:46', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(8, 'back-ups cs 650 apc', 48, 4, '2017-02-24', '2017-02-23', 'Se adelantó S/. 2.00 de S/. 50.00 el día 24/02/2017<br>transformador blanco', 60, 0, 8, b'0', b'0', '2017-02-06 13:36:28', 2, 1, '', 82.56, 'Yuri Paola', '2017-06-28 20:05:24', b'0', '0', b'0'),
(9, 'cubiertos rena ware + cortinas', 400, 4, '2017-01-26', '2017-02-26', '26 cubiertos ', 480, 0, 9, b'0', b'0', '2017-02-06 13:45:32', 2, 1, '', 832, 'Aumbbel', '2017-07-31 23:58:02', b'0', '0', b'0'),
(10, 'celular huawei g6 l33', 51.2, 4, '2017-04-08', '2017-02-28', 'Se adelantó S/. 16.00 de S/. 67.20 el día 08/04/2017<br>Se adelantó S/. 12.80 de S/. 80.00 el día 02/03/2017<br>', 92.8, 0, 10, b'0', b'0', '2017-02-06 13:52:49', 2, 1, '', 73.73, 'Pilar Maria', '2017-06-24 09:11:27', b'0', '0', b'0'),
(11, 'laptop lenovo b50-80', 500, 4, '2017-02-03', '2017-03-03', 'nuevo+cargador+boleta (en caja)', 580, 0, 11, b'0', b'0', '2017-02-06 13:56:58', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(12, 'celular lg g3 + dvd', 150, 4, '2017-02-06', '2017-03-06', '', 174, 0, 12, b'0', b'0', '2017-02-06 14:03:55', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(13, 'reloj casio 5468', 100, 4, '2017-01-10', '2017-02-10', 'en caja', 120, 0, 13, b'0', b'0', '2017-02-06 14:19:15', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(14, 'horno microondas color negro', 105, 4, '2017-01-11', '2017-02-11', '', 126, 0, 14, b'0', b'0', '2017-02-06 14:38:37', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(15, 'camara digital finefix ', 25.2, 4, '2017-03-25', '2017-03-07', 'Se adelantó S/. 4.80 de S/. 30.00 el día 25/03/2017<br>con memoria 8gb ', 34.8, 0, 15, b'0', b'0', '2017-02-07 17:46:08', 2, 1, '', 44.35, 'Aumbbel', '2017-08-01 00:48:17', b'0', '0', b'0'),
(16, 'licuadora taurus + celular huawey', 100, 4, '2017-02-07', '2017-03-07', '', 116, 0, 16, b'0', b'0', '2017-02-07 17:51:17', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(17, 'laptop dell inspiracion 14 serie 3000', 336, 4, '2017-03-06', '2017-03-06', 'Se adelantó S/. 64.00 de S/. 400.00 el día 06/03/2017<br>funda+cargador+mause', 464, 0, 17, b'0', b'0', '2017-02-07 17:54:08', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(18, '2 incubadoras automaticas', 170, 4, '2017-02-07', '2017-03-07', '', 197.2, 0, 18, b'0', b'0', '2017-02-07 17:57:25', 2, 1, '', 285.6, 'manrique', '2017-06-05 21:14:51', b'0', '0', b'0'),
(19, 'frigobar daewoo color negro', 168, 4, '2017-03-13', '2017-03-08', 'Se adelantó S/. 32.00 de S/. 200.00 el día 13/03/2017<br>', 232, 0, 19, b'0', b'0', '2017-02-08 15:20:29', 2, 1, '', 248.64, 'manrique', '2017-06-05 21:15:06', b'0', '0', b'0'),
(20, 'laptop acer', 200, 4, '2017-02-09', '2017-03-09', 'le faltan tres teclas ', 232, 0, 20, b'0', b'0', '2017-02-09 16:39:09', 2, 1, '', 360, 'Yuri Paola', '2017-06-23 09:56:14', b'0', '0', b'0'),
(21, 'celular huawei ascend g7 blanco', 80, 4, '2017-02-09', '2017-03-09', 'pantalla rota ', 92.8, 0, 15, b'0', b'0', '2017-02-09 18:34:00', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(22, 'bluray sony', 450, 4, '2016-09-05', '2016-10-05', 'laptop hpi3 con cargador (vendido)', 540, 0, 21, b'0', b'0', '2017-02-09 19:12:54', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(23, 'camara profesional canon', 700, 4, '2016-10-28', '2016-11-28', '', 840, 0, 22, b'0', b'0', '2017-02-09 19:16:56', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(51, 'olla renaware', 300, 4, '2016-09-30', '2016-10-30', '', 360, 0, 50, b'0', b'0', '2017-02-10 16:27:41', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(26, 'calculadora hp', 80, 4, '2016-10-04', '2016-11-04', '', 96, 0, 25, b'0', b'0', '2017-02-09 19:30:32', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(27, '2 mochilas', 590, 4, '2016-10-11', '2016-11-11', 'hom dvd+camara+laptop', 708, 0, 26, b'0', b'0', '2017-02-09 19:33:28', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(28, 'equipo de sonido+monitor+blueray+computador i5', 520, 4, '2016-10-13', '2016-11-13', '', 624, 0, 27, b'0', b'0', '2017-02-09 19:35:55', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(29, 'laptop hp', 200, 4, '2016-10-25', '2016-11-25', '', 240, 0, 28, b'0', b'0', '2017-02-09 19:41:13', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(30, 'equipo de sonido lg', 200, 4, '2016-10-26', '2016-11-26', '', 240, 0, 29, b'0', b'0', '2017-02-09 19:43:04', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(31, 'plancha +equipo', 200, 4, '2016-11-11', '2016-12-11', '', 240, 0, 30, b'0', b'0', '2017-02-09 19:46:47', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(32, 'cpu intel i3+monitor advance', 200, 4, '2016-11-14', '2016-12-14', '', 240, 0, 31, b'0', b'0', '2017-02-09 19:50:07', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(33, 'laptop i7+impresora hp nueva', 1000, 4, '2016-11-15', '2016-12-15', '', 1200, 0, 32, b'0', b'0', '2017-02-09 19:52:48', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(34, 'tv samsung', 150, 4, '2016-11-15', '2016-12-15', '', 180, 0, 33, b'0', b'0', '2017-02-09 19:54:32', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(35, 'olla arrocera 6l', 70, 4, '2016-11-16', '2016-12-16', '', 84, 0, 34, b'0', b'0', '2017-02-09 19:56:18', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(36, 'guitarra electronica', 100, 4, '2016-11-17', '2016-12-17', '', 120, 0, 35, b'0', b'0', '2017-02-09 19:58:05', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(37, 'terma solar', 500, 4, '2016-11-19', '2016-12-19', '', 600, 0, 36, b'0', b'0', '2017-02-09 19:59:57', 2, 1, '', 1120, 'manrique', '2017-06-23 19:38:48', b'0', '0', b'0'),
(38, 'impresora canon hg 2410', 60, 4, '2016-11-28', '2016-12-28', '', 72, 0, 37, b'0', b'0', '2017-02-09 20:01:48', 2, 1, '', 124.8, 'manrique', '2017-06-05 21:14:06', b'0', '0', b'0'),
(50, '2 tiquetera epson', 600, 4, '2016-09-28', '2016-10-28', '', 720, 0, 49, b'0', b'0', '2017-02-10 16:25:09', 2, 1, '', 1464, 'manrique', '2017-06-05 21:13:51', b'0', '0', b'0'),
(40, 'laptop toshiba core i3', 350, 4, '2016-12-03', '2017-01-03', '', 420, 0, 39, b'0', b'0', '2017-02-09 20:05:36', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(41, 'tablet acer', 80, 4, '2016-12-12', '2017-01-12', '', 96, 0, 40, b'0', b'0', '2017-02-09 20:07:48', 2, 1, '', 147.2, 'Yuri Pahola', '2017-05-04 18:59:03', b'0', '0', b'0'),
(42, 'gps', 68, 4, '2017-02-15', '2017-01-12', 'Se adelantó S/. 32.00 de S/. 100.00 el día 15/02/2017<br>', 120, 0, 41, b'0', b'0', '2017-02-09 20:09:44', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(43, 'laptop i5 con cargador y estuche azul', 550, 4, '2016-12-14', '2017-01-14', '', 660, 0, 42, b'0', b'0', '2017-02-09 20:11:52', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(44, 'laptop amd a8 con cargador y estuche', 400, 4, '2016-12-15', '2017-01-15', '', 480, 0, 43, b'0', b'0', '2017-02-09 20:13:30', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(45, 'camara sony lens g', 180, 4, '2016-12-16', '2017-01-16', '', 216, 0, 44, b'0', b'1', '2017-02-09 20:15:14', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(46, 'tablet teraware', 60, 4, '2016-12-01', '2017-01-01', '', 72, 0, 45, b'0', b'0', '2017-02-09 20:17:13', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(47, 'laptop con mochila ploma', 800, 4, '2017-01-06', '2017-02-06', '', 960, 0, 46, b'0', b'0', '2017-02-09 20:19:06', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(48, 'laptop hp pavilion', 500, 4, '2017-01-07', '2017-02-07', '', 600, 0, 47, b'0', b'0', '2017-02-09 20:20:40', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(49, 'Tv 3d Smart Samsung 40 6400', 500, 4, '2017-02-10', '2017-03-10', 'Accesorios completos(en caja)', 580, 0, 48, b'0', b'0', '2017-02-10 12:33:53', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(52, 'laptop hp i3', 300, 4, '2016-12-01', '2017-02-01', '', 408, 0, 51, b'0', b'0', '2017-02-10 16:47:31', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(53, 'camara canon powershota2600', 60, 4, '2017-02-10', '2017-02-11', 'estuche y cargador', 62.4, 0, 52, b'0', b'0', '2017-02-10 18:18:09', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(54, 'tablet advance con cargador', 80, 4, '2017-02-11', '2017-03-11', '', 92.8, 0, 53, b'0', b'0', '2017-02-11 12:10:09', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(55, 'celular mod XD', 19, 4, '2017-09-19', '2017-02-14', 'Se adelantó S/. 1.00 de S/. 20.00 el día 03/03/2017<br>Se adelantó S/. 1.00 de S/. 21.00 el día 03/03/2017<br>Se adelantó S/. 2.00 de S/. 23.00 el día 03/03/2017<br>Se adelantó S/. 1.00 de S/. 24.00 el día 24/02/2017<br>Se adelantó S/. 1.00 de S/. 25.00 el día 24/02/2017<br>', 26, 71.5, 54, b'0', b'0', '2017-02-13 12:43:31', 9, 2, '19/09/2017', 0, '', '', b'0', '0', b'0'),
(56, 'taza chocolate', 160, 4, '2017-09-19', '2017-01-11', 'Se adelantó S/. 30.00 de S/. -30.00 el día 24/02/2017<br>Se adelantó S/. 10.00 de S/. -20.00 el día 24/02/2017<br>Se adelantó S/. 15.00 de S/. -5.00 el día 24/02/2017<br>Se adelantó S/. 1.00 de S/. -4.00 el día 24/02/2017<br>Se adelantó S/. 1.00 de S/. -3.00 el día 24/02/2017<br>Se adelantó S/. 1.00 de S/. -2.00 el día 24/02/2017<br>Se adelantó S/. 2.00 de S/. 0.00 el día 24/02/2017<br>Se adelantó S/. 1 del monto S/. 1.00el día 15/02/2017<br>Se adelantó S/. 1 del monto S/. 2.00el día 15/02/2017<br>', 2.08, 0, 54, b'0', b'0', '2017-02-13 12:44:43', 9, 2, '19/09/2017', 224, '9', '2017-05-04 12:54:14', b'0', '0', b'0'),
(57, 'bicicleta bianss', 50, 4, '2017-02-13', '2017-03-13', '', 58, 0, 55, b'0', b'0', '2017-02-13 15:32:14', 2, 1, '', 82, 'manrique', '2017-06-05 21:16:16', b'0', '0', b'0'),
(58, 'laptop hp envy i7', 700, 4, '2017-02-13', '2017-03-13', 'laptop con cargador', 812, 0, 56, b'0', b'0', '2017-02-13 16:03:28', 2, 1, '', 1316, 'Aumbbel', '2017-07-11 12:52:23', b'0', '0', b'0'),
(59, 'pc +pantalla lg+parlantes+transformador', 170, 4, '2017-02-20', '2017-03-13', 'Se adelantó S/. 30.00 de S/. 200.00 el día 20/02/2017<br>', 232, 0, 57, b'0', b'0', '2017-02-13 16:34:48', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(60, 'tv lg 32ln540b', 300, 4, '2017-02-13', '2017-03-13', '', 348, 0, 58, b'0', b'0', '2017-02-13 17:27:00', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(61, 'laptop hp pavilion 14 notebook con cargador', 300, 4, '2017-02-13', '2017-03-13', '', 348, 0, 59, b'0', b'0', '2017-02-13 17:49:57', 2, 1, '', 444, 'Yuri Pahola', '2017-05-04 18:44:44', b'0', '0', b'0'),
(62, 'laptop advance i3 con cargador', 107, 4, '2017-02-13', '2017-03-13', '', 124.12, 0, 57, b'0', b'0', '2017-02-13 19:00:44', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(63, 'televisor noc le19w037', 100, 4, '2017-02-14', '2017-03-14', 'con su control', 116, 0, 60, b'0', b'0', '2017-02-14 11:06:32', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(64, 'Celular modelo zte', 140, 4, '2017-09-19', '2017-04-08', 'Se adelantó S/. 10.00 de S/. 150.00 el día 15/02/2017<br>Se adelantó S/. 1.00 de S/. 151.00 el día 15/02/2017<br>Se adelantó S/. 3.00 de S/. 154.00 el día 15/02/2017<br>Se adelantó S/. 4.00 de S/. 158.00 el día 15/02/2017<br>Se adelantó S/. 2.00 de S/. 160.00 el día 15/02/2017<br>Se adelantó S/. 4.00 de S/. 164.00 el día 15/02/2017<br>Se adelantó S/. 1.00 de S/. 165.00 el día 15/02/2017<br>Se adelantó S/. 1.00 de S/. 166.00 el día 15/02/2017<br>Se adelantó S/. 5.00 de S/. 171.00 el día 15/02/2017<br>Se adelantó S/. 3.00 de S/. 174.00 el día 15/02/2017<br>Se adelantó S/. 3.00 de S/. 177.00 el día 15/02/2017<br>Se adelantó S/. 2.00 del monto S/. 179.00 el día 15/02/2017<br>Se adelantó S/. 1 del monto S/. 180.00el día 15/02/2017<br>', 237.6, 71, 54, b'0', b'0', '2017-02-14 14:05:50', 9, 2, '19/09/2017', 0, '', '', b'0', '0', b'0'),
(65, 'Deja su cubo antiesess', 100, 4, '2017-02-14', '2017-02-15', 'Deja su cubo antiesess', 104, 44, 61, b'0', b'1', '2017-02-14 14:31:23', 10, 3, '', 0, '', '', b'0', '0', b'0'),
(66, 'pc advance intel core duo', 80, 4, '2017-02-15', '2017-03-15', '', 92.8, 0, 62, b'0', b'0', '2017-02-15 13:30:53', 2, 1, '', 131.2, 'manrique', '2017-06-05 21:16:38', b'0', '0', b'0'),
(67, 'taladro repli. bosch(verde)', 40, 4, '2017-02-16', '2017-03-16', '', 46.4, 0, 63, b'0', b'0', '2017-02-16 13:58:46', 2, 1, '', 65.6, 'Yuri Paola', '2017-06-08 19:44:36', b'0', '0', b'0'),
(68, 'maquina vibradora para piso marca honda G200', 200, 4, '2017-02-20', '2017-03-20', '', 232, 0, 64, b'0', b'0', '2017-02-20 10:27:08', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(69, 'celular huawei cun l03', 100, 4, '2017-02-20', '2017-03-20', '', 116, 0, 65, b'0', b'0', '2017-02-20 12:20:53', 2, 1, '', 172, 'Aumbbel', '2017-06-26 20:22:24', b'0', '0', b'0'),
(70, 'equipo de sonido l6-3420 + olla arrocera rc 6', 101, 4, '2017-04-03', '2017-02-14', 'Se adelantó S/. 24.00 de S/. 125.00 el día 03/04/2017<br>Se adelantó S/. 25.00 de S/. 150.00 el día 04/03/2017<br>', 180, 0, 66, b'0', b'1', '2017-02-20 12:57:52', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(71, 'guitarra electroacustica villalta', 100, 4, '2017-02-20', '2017-04-20', '', 136, 0, 67, b'0', b'0', '2017-02-20 14:08:25', 2, 1, '', 144, 'Yuri Pahola', '2017-05-04 18:41:46', b'0', '0', b'0'),
(72, '3 celulares htc desire 626s', 500, 4, '2017-02-21', '2017-03-21', '', 580, 0, 68, b'0', b'0', '2017-02-21 09:52:04', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(73, 'llanta+gata+triangulo+estuche (5 herramientas) ', 100, 4, '2017-02-22', '2017-03-22', '', 116, 0, 69, b'0', b'0', '2017-02-22 16:50:08', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(74, '2 cpu + 2 monitor samsung', 1000, 4, '2017-02-23', '2017-03-23', '', 1160, 0, 4, b'0', b'0', '2017-02-23 19:01:40', 2, 1, '', 1600, 'Yuri Paola', '2017-06-08 19:46:49', b'0', '0', b'0'),
(75, 'laptop hp probook 4440 con escuche', 300, 4, '2017-02-24', '2017-03-24', '', 348, 0, 70, b'0', b'0', '2017-02-24 09:49:29', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(76, 'camara canon sx50hs', 160, 4, '2017-04-28', '2017-03-24', 'Se adelantó S/. 90.00 de S/. 250.00 el día 28/04/2017<br>', 290, 90, 71, b'0', b'0', '2017-02-24 18:07:38', 2, 1, '', 230.4, 'Yuri Paola', '2017-07-14 10:39:57', b'0', '0', b'0'),
(77, 'moto pulsar rs 200 amarillo+casco+tarjeta+soat', 2000, 4, '2017-02-24', '2017-03-24', '', 2320, 0, 72, b'0', b'0', '2017-02-24 19:26:10', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(78, 'moto pulsar rs 200 amarillo+casco+tarjeta+soat', 2000, 4, '2017-02-24', '2017-03-24', '', 2320, 0, 73, b'0', b'0', '2017-02-24 19:26:11', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(79, 'computador de cabina', 400, 4, '2017-02-28', '2017-03-28', '', 464, 0, 65, b'0', b'0', '2017-02-28 12:02:23', 2, 1, '', 640, 'Yuri Paola', '2017-06-08 19:47:46', b'0', '0', b'0'),
(80, 'Playstation 3 Cech-4001b con comando y 5 juegos', 150, 4, '2017-02-28', '2017-03-28', 'comando Genérico ', 174, 0, 74, b'0', b'0', '2017-02-28 13:56:43', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(81, '40 pares de zapatos', 600, 4, '2017-03-01', '2017-05-01', '', 816, 0, 75, b'0', b'0', '2017-03-01 13:09:24', 2, 1, '', 888, 'Yuri Paola', '2017-05-22 10:01:57', b'0', '0', b'0'),
(82, 'auto daewoo lanos se- verde : placa. a4N-580', 1500, 4, '2017-03-02', '2017-03-09', '', 1560, 0, 76, b'0', b'0', '2017-03-02 17:55:57', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(83, 'laptop levono con cargador y estuche', 300, 4, '2017-03-04', '2017-04-04', '', 360, 0, 77, b'0', b'0', '2017-03-04 12:37:50', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(84, 'televisor lg 32lh570b', 300, 4, '2017-03-04', '2017-04-04', '', 360, 0, 78, b'0', b'0', '2017-03-04 13:31:52', 2, 1, '', 468, 'Yuri Paola', '2017-06-08 19:48:15', b'0', '0', b'0'),
(85, 'filtro de agua rena ware', 400, 4, '2017-03-06', '2017-04-06', '', 480, 0, 79, b'0', b'0', '2017-03-06 11:56:47', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(86, '3 carritos emolienteros', 1200, 4, '2017-03-07', '2017-04-07', '', 1440, 0, 80, b'0', b'1', '2017-03-07 15:37:02', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(87, 'laptop lenovo ideapad 510 i7', 756, 4, '2017-04-11', '2017-04-09', 'Se adelantó S/. 144.00 de S/. 900.00 el día 11/04/2017<br>', 1080, 0, 81, b'0', b'0', '2017-03-09 12:46:02', 2, 1, '', 1028.16, 'Yuri Paola', '2017-06-12 10:11:51', b'0', '0', b'0'),
(88, 'microondas daewoo kor-190 n', 30, 4, '2017-03-09', '2017-04-09', '', 36, 0, 82, b'0', b'0', '2017-03-09 17:25:37', 2, 1, '', 45.6, 'manrique', '2017-06-05 21:17:05', b'0', '0', b'0'),
(89, 'laptop asus m:x70i s:8220', 850, 4, '2017-03-10', '2017-04-10', '', 1020, 0, 83, b'0', b'0', '2017-03-10 11:51:58', 2, 1, '', 1394, 'Yuri Paola', '2017-06-28 20:05:55', b'0', '0', b'0'),
(90, 'cocina de mesa visioneer', 50, 4, '2017-03-10', '2017-04-10', '', 60, 0, 84, b'0', b'0', '2017-03-10 14:36:47', 2, 1, '', 78, 'Yuri Paola', '2017-06-14 18:56:13', b'0', '0', b'0'),
(91, '2 congas con funda-lpy y 1 parche remo', 300, 4, '2017-03-10', '2017-04-10', '', 360, 0, 85, b'0', b'0', '2017-03-10 15:03:28', 2, 1, '', 396, 'Yuri Pahola', '2017-05-04 18:42:06', b'0', '0', b'0'),
(92, 'televisor samsung un40jh5005g', 150, 4, '2017-03-11', '2017-04-11', '', 180, 0, 86, b'0', b'0', '2017-03-11 10:06:40', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(93, 'laptop toshiba c55-b5117km', 140, 4, '2017-03-11', '2017-04-11', '', 168, 0, 87, b'0', b'0', '2017-03-11 11:06:00', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(94, 'fotocopiadora hp laser jet m5035 mfp', 350, 4, '2017-03-13', '2017-04-13', '', 420, 0, 88, b'0', b'0', '2017-03-13 20:37:08', 2, 1, '', 532, 'Yuri Paola', '2017-06-08 19:48:32', b'0', '0', b'0'),
(95, 'chocolatera rena ware, thomas th-135, imaco grill ig2815a', 230, 4, '2017-03-14', '2017-04-14', '', 276, 0, 89, b'0', b'0', '2017-03-14 14:05:24', 2, 1, '', 340.4, 'Yuri Paola', '2017-06-05 14:47:13', b'0', '0', b'0'),
(96, 'laptop lenovo z50', 1100, 4, '2017-03-17', '2017-04-17', '', 1320, 0, 90, b'0', b'0', '2017-03-17 13:13:35', 2, 1, '', 1760, 'Yuri Paola', '2017-06-28 20:06:18', b'0', '0', b'0'),
(97, 'televisor samsung + celular sony c5', 500, 4, '2017-03-17', '2017-04-17', '', 600, 0, 91, b'0', b'0', '2017-03-17 14:00:39', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(98, 'laptop hp pavilion amd 8', 400, 4, '2017-03-18', '2017-04-18', '', 480, 0, 92, b'0', b'0', '2017-03-18 13:03:20', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(99, 'laptop hp 455 + impresora hp 3545', 150, 4, '2017-03-20', '2017-04-20', '', 180, 0, 3, b'0', b'0', '2017-03-20 15:47:54', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(100, 'teodolito nikon ne-20h + nivel sokkia 262358', 1000, 4, '2017-03-20', '2017-04-20', '', 1200, 0, 93, b'0', b'0', '2017-03-20 20:19:35', 2, 1, '', 1760, 'Aumbbel', '2017-07-31 23:58:24', b'0', '0', b'0'),
(101, 'laptop hp 15 i3', 350, 4, '2017-03-21', '2017-04-21', '', 420, 0, 94, b'0', b'0', '2017-03-21 14:24:41', 2, 1, '', 560, 'Yuri Paola', '2017-06-28 20:13:50', b'0', '0', b'0'),
(102, 'Camara Nikon Coolpix S9900', 200, 4, '2017-03-22', '2017-04-22', '', 240, 0, 95, b'0', b'0', '2017-03-22 12:26:06', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(103, 'televisor lg 24MT47A-pm', 200, 4, '2017-03-23', '2017-04-23', '', 240, 0, 96, b'0', b'0', '2017-03-23 16:48:58', 2, 1, '', 312, 'Yuri Paola', '2017-06-28 20:07:03', b'0', '0', b'0'),
(104, 'camara canon eos 40d', 280, 4, '2017-03-24', '2017-04-24', '', 336, 0, 97, b'0', b'0', '2017-03-24 18:18:45', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(105, 'zapatos 43', 300, 4, '2017-03-24', '2017-04-24', '', 360, 0, 75, b'0', b'0', '2017-03-24 19:36:17', 2, 1, '', 408, 'Yuri Paola', '2017-05-22 10:01:32', b'0', '0', b'0'),
(106, 'laptop toshiba satellite p55t-c5114', 1200, 10, '2017-03-25', '2017-03-27', '', 1320, 0, 98, b'0', b'0', '2017-03-25 16:09:31', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(107, 'televisor panasonic', 130, 4, '2017-03-28', '2017-03-30', '', 135.2, 0, 99, b'0', b'0', '2017-03-28 11:39:31', 2, 1, '', 192.4, 'Yuri Paola', '2017-06-14 18:55:53', b'0', '0', b'0'),
(108, 'toshiba laptop satelite c55 b5115km', 200, 4, '2017-03-28', '2017-04-28', '', 240, 0, 100, b'0', b'0', '2017-03-28 13:39:52', 2, 1, '', 312, 'Yuri Paola', '2017-06-28 20:07:31', b'0', '0', b'0'),
(109, 'lavadora samsung 5k', 70, 4, '2017-03-28', '2017-04-28', '', 84, 0, 101, b'0', b'0', '2017-03-28 17:17:27', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(110, 'Estacion Total  Es-105 Incluye Tripode Prisma Baston', 2500, 4, '2017-03-29', '2017-04-29', '', 3000, 0, 102, b'0', b'0', '2017-03-29 12:58:02', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(111, 'laotop lenovo g40-80(con cargador)+ lenovo g580', 800, 4, '2017-03-31', '2017-04-30', '', 960, 0, 103, b'0', b'0', '2017-03-31 16:59:12', 2, 1, '', 1152, 'Yuri Paola', '2017-06-14 18:59:48', b'0', '0', b'0'),
(112, 'Martillo Bosch Gsh 16', 500, 4, '2017-03-31', '2017-04-30', '', 600, 0, 104, b'0', b'0', '2017-03-31 17:15:52', 2, 1, '', 620, 'Yuri Paola', '2017-05-11 10:23:14', b'0', '0', b'0'),
(113, 'play 3 cech-4011b (mando+juego+2cables)', 300, 4, '2017-03-31', '2017-04-30', '', 360, 0, 105, b'0', b'0', '2017-03-31 17:29:07', 2, 1, '', 456, 'Yuri Paola', '2017-06-28 20:07:51', b'0', '0', b'0'),
(114, 'celular samsung j7', 250, 4, '2017-03-31', '2017-04-14', '', 270, 0, 106, b'0', b'0', '2017-03-31 19:43:38', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(115, 'Laptop HP Probook 4440 Core i5', 300, 4, '2017-04-01', '2017-04-29', 'Laptop sin cargador, solo se le entrega S/. 250. En espera de que entregue cargador lunes 4 de abril.', 348, 0, 70, b'0', b'0', '2017-04-01 09:20:44', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(116, 'Laptop Core i3 Lenovo - SN CB25877919', 300, 4, '2017-04-01', '2017-04-29', 'Con cargador', 348, 0, 107, b'0', b'0', '2017-04-01 15:56:38', 2, 1, '', 432, 'Yuri Paola', '2017-06-14 18:59:11', b'0', '0', b'0'),
(117, 'Laptop Core i3 lenovo con cargador', 300, 4, '2017-04-01', '2017-04-29', '', 348, 0, 107, b'0', b'0', '2017-04-01 15:59:14', 2, 1, '', 420, 'Yuri Paola', '2017-06-08 19:51:05', b'0', '0', b'0'),
(118, 'hp pavilion x360', 500, 10, '2017-04-03', '2017-04-05', '', 550, 0, 108, b'0', b'0', '2017-04-03 18:56:12', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(119, 'estacion total sokkia cx-105', 2500, 4, '2017-04-04', '2017-04-11', '', 2600, 0, 102, b'0', b'0', '2017-04-04 17:20:33', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(120, 'camara canon revel t5', 600, 4, '2017-04-04', '2017-05-04', '', 720, 0, 109, b'0', b'0', '2017-04-05 13:02:52', 2, 1, '', 816, 'Yuri Paola', '2017-05-31 12:40:38', b'0', '0', b'0'),
(121, 'terma', 80, 10, '2017-04-17', '2017-04-06', 'Se adelantó S/. 10.00 de S/. 90.00 el día 17/04/2017<br>Se adelantó S/. 10.00 de S/. 100.00 el día 17/04/2017<br>', 110, 0, 54, b'0', b'0', '2017-04-05 16:57:12', 9, 2, '', 88, 'Yuri Pahola', '2017-05-04 18:57:00', b'0', '0', b'0'),
(122, 'motocicleta yamaha fz negro(b4-2306)', -666, 4, '2017-07-06', '2017-05-07', 'Se adelantó S/. 110.00 de S/. -556.00 el día 06/07/2017<br>Se adelantó S/. 550.00 de S/. -6.00 el día 06/07/2017<br>Se adelantó S/. 550.00 de S/. 544.00 el día 06/07/2017<br>Se adelantó S/. 128.00 de S/. 672.00 el día 07/06/2017<br>Se adelantó S/. 128.00 de S/. 800.00 el día 04/05/2017<br>', 960, 1466, 110, b'0', b'0', '2017-04-07 10:14:24', 2, 1, '', -799.2, 'Yuri Paola', '2017-08-09 13:08:01', b'0', '0', b'0'),
(123, 'calculadora hp', 70, 4, '2017-04-07', '2017-05-07', '', 84, 0, 111, b'0', b'0', '2017-04-07 12:12:28', 2, 1, '', 103.6, 'Yuri Paola', '2017-06-28 20:04:53', b'0', '0', b'0'),
(124, 'televisor 42\" lg', 250, 4, '2017-04-07', '2017-05-07', '', 300, 0, 112, b'0', b'0', '2017-04-07 12:38:52', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(125, 'una motocicleta marca barsha modelo lamger r17 placa 1028-0w', 350, 4, '2017-04-09', '2017-05-04', 'DEJA TARJETA DE PROPIEDAD, CASCO Y LLAVE.', 406, 0, 113, b'0', b'0', '2017-04-09 14:03:07', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(126, 'cpu + monitor + teclado + mause', 150, 4, '2017-04-10', '2017-05-10', '', 180, 0, 114, b'0', b'0', '2017-04-10 17:44:43', 2, 1, '', 222, 'Yuri Paola', '2017-06-28 20:08:05', b'0', '0', b'0'),
(127, 'mini componente samsung mx-j630 230', 64, 4, '2017-05-11', '2017-04-24', 'Se adelantó S/. 16.00 de S/. 80.00 el día 11/05/2017<br>', 86.4, 16, 115, b'0', b'0', '2017-04-10 18:37:40', 2, 1, '', 87.04, 'Beatriz', '2017-07-08 18:02:46', b'0', '0', b'0'),
(128, 'bicicleta de niño + bluray + reloj seiko', 0, 18, '2017-04-17', '2017-05-11', 'Se adelantó S/. 200.00 de S/. 200.00 el día 17/04/2017<br>', 380, 0, 116, b'0', b'0', '2017-04-11 10:27:05', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(129, 'celular j3 + llanta + 5 herramientas', 200, 4, '2017-07-17', '2017-05-11', 'Se canceló el interés S/. 40.00 de el día 17/07/2017<br>Se canceló el interés S/. 80.00 de el día 14/06/2017<br>Se canceló el interés S/. 40.00 de el día 12/05/2017<br>', 240, 0, 69, b'0', b'0', '2017-04-11 10:50:20', 2, 1, '17/07/2017', 224, 'Yuri Paola', '2017-08-02 16:36:08', b'0', '0', b'0'),
(130, 'tablet acer', 40, 4, '2017-06-19', '2017-05-11', 'Se adelantó S/. 10.00 de S/. 50.00 el día 19/06/2017<br>Se canceló el interés S/. 20.00 de el día 19/06/2017<br>', 60, 10, 117, b'0', b'0', '2017-04-11 11:07:14', 2, 1, '19/06/2017', 44.8, 'Yuri Paola', '2017-07-10 16:15:42', b'0', '0', b'0'),
(131, 'moto r15', 1500, 4, '2017-04-11', '2017-05-11', '', 1800, 0, 118, b'0', b'0', '2017-04-11 14:57:54', 2, 1, '', 2220, 'Yuri Paola', '2017-06-28 20:08:55', b'0', '0', b'0'),
(132, 'laptop hp +cargador', 300, 4, '2017-04-08', '2017-05-08', '', 360, 0, 119, b'0', b'0', '2017-04-11 17:25:14', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(133, 'laptop hp 14 r003la', 200, 4, '2017-04-11', '2017-05-11', '', 240, 0, 120, b'0', b'0', '2017-04-11 18:27:59', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(134, 'guitarra eléctrica jt 690 -fr', 200, 4, '2017-04-12', '2017-04-26', '', 216, 0, 121, b'0', b'0', '2017-04-12 11:53:44', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(135, 'laptop toshiba satellite con cargador', 150, 4, '2017-04-12', '2017-04-26', '', 162, 0, 122, b'0', b'0', '2017-04-12 12:02:53', 2, 1, '', 216, 'Yuri Paola', '2017-06-28 20:10:59', b'0', '0', b'0'),
(136, 'gpsmap 62s garmin', 200, 4, '2017-04-12', '2017-04-30', '', 224, 0, 123, b'0', b'0', '2017-04-12 12:24:15', 2, 1, '', 288, 'Yuri Paola', '2017-06-28 20:10:19', b'0', '0', b'0'),
(137, 'laptop lenovo + disco duro 1tb', 300, 4, '2017-04-12', '2017-05-12', '', 360, 0, 124, b'0', b'0', '2017-04-12 16:28:45', 2, 1, '', 432, 'Yuri Paola', '2017-06-28 20:09:58', b'0', '0', b'0'),
(138, 'laptop hp blanco con cargador', 150, 4, '2017-04-12', '2017-05-12', '', 180, 0, 125, b'0', b'0', '2017-04-12 17:35:50', 2, 1, '', 216, 'Yuri Paola', '2017-06-28 20:14:49', b'0', '0', b'0'),
(139, 'laptop asus x540l i3', 350, 4, '2017-04-13', '2017-05-13', '', 420, 0, 126, b'0', b'0', '2017-04-13 10:58:40', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(140, 'caja con herramientas', 90, 4, '2017-09-19', '2017-05-01', 'Se adelantó S/. 10.00 de S/. 100.00 el día 17/04/2017<br>', 108, 0, 54, b'0', b'0', '2017-04-17 11:20:34', 9, 2, '19/09/2017', 101, '', '2017-05-04 17:56:38', b'0', '0', b'0'),
(141, 'consola de videojuegos', 300, 4, '2017-04-17', '2017-04-18', '', 330, 0, 54, b'0', b'0', '2017-04-17 12:09:16', 9, 2, '', 336, '', '2017-05-04 13:55:54', b'0', '0', b'0'),
(142, 'celular motorola x1', 200, 4, '2017-04-17', '2017-04-18', 'Se adelantó S/. 10.00 de S/. 210.00 el día 17/04/2017<br>Se adelantó S/. 5.00 de S/. 215.00 el día 17/04/2017<br>Se adelantó S/. 3.00 de S/. 218.00 el día 17/04/2017<br>Se adelantó S/. 6.00 de S/. 224.00 el día 17/04/2017<br>Se adelantó S/. 11.00 de S/. 235.00 el día 17/04/2017<br>Se adelantó S/. 5.00 de S/. 240.00 el día 17/04/2017<br>Se adelantó S/. 10.00 de S/. 250.00 el día 17/04/2017<br>', 275, 35, 127, b'0', b'0', '2017-04-17 12:33:11', 9, 2, '', 224, '', '2017-05-04 18:10:34', b'0', '0', b'0'),
(143, 'ps 3 cech4211a + bluray lg bp450', 150, 4, '2017-04-17', '2017-04-18', '', 165, 0, 128, b'0', b'0', '2017-04-17 12:44:39', 2, 1, '', 216, 'Yuri Paola', '2017-06-28 20:11:32', b'0', '0', b'0'),
(144, 'horno microondas ge jes700pgk', 70, 4, '2017-04-17', '2017-04-18', '', 77, 0, 129, b'0', b'0', '2017-04-17 13:10:48', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(145, 'laptop hp amd a8', 400, 4, '2017-04-17', '2017-04-18', '', 440, 0, 130, b'0', b'0', '2017-04-17 18:52:03', 2, 1, '', 656, 'Aumbbel', '2017-08-01 00:48:57', b'0', '0', b'0'),
(146, 'camara filmadora nikon + cargador', 200, 4, '2017-04-18', '2017-04-19', '', 220, 0, 95, b'0', b'1', '2017-04-18 15:50:25', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(147, 'laptop toshiba satellite ci5 u940 - sp4301gl', 300, 4, '2017-04-19', '2017-04-20', '', 330, 0, 131, b'0', b'0', '2017-04-19 16:54:45', 2, 1, '', 348, 'Yuri Paola', '2017-05-17 18:38:45', b'0', '0', b'0'),
(148, 'laptop toshiba s55t-a', 350, 4, '2017-04-20', '2017-04-21', '', 385, 0, 132, b'0', b'0', '2017-04-20 11:26:55', 2, 1, '', 420, 'Yuri Paola', '2017-05-25 10:21:18', b'0', '0', b'0'),
(149, 'tv samsung 45\"', 300, 4, '2017-04-20', '2017-04-21', '', 330, 0, 133, b'0', b'0', '2017-04-20 16:37:59', 2, 1, '', 420, 'Yuri Paola', '2017-06-28 20:10:41', b'0', '0', b'0'),
(150, 'mini componente lg mc 8360', 300, 4, '2017-04-20', '2017-04-21', '', 330, 0, 134, b'0', b'0', '2017-04-20 18:29:19', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(151, 'bluray bdp 1300', 70, 4, '2017-04-21', '2017-04-22', '', 77, 0, 116, b'0', b'0', '2017-04-21 09:57:44', 2, 1, '', 78.4, 'Yuri Pahola', '2017-05-12 16:17:02', b'0', '0', b'0'),
(152, 'camara canon t5', 300, 4, '2017-04-21', '2017-04-22', '', 330, 0, 109, b'0', b'0', '2017-04-21 17:42:29', 2, 1, '', 372, 'Yuri Paola', '2017-05-31 12:41:25', b'0', '0', b'0'),
(153, 'moto honda cb190r', 1700, 4, '2017-04-22', '2017-04-23', '', 1870, 0, 135, b'0', b'0', '2017-04-22 12:33:52', 2, 1, '', 2040, 'Yuri Pahola', '2017-05-23 14:27:49', b'0', '0', b'0'),
(154, 'laptop hp mas cargador', 150, 4, '2017-04-24', '2017-04-25', 'Se canceló el interés S/. 36.00 de el día 02/06/2017<br>Se canceló el interés S/. 36.00 de el día 02/06/2017<br>', 165, 0, 136, b'0', b'0', '2017-04-24 14:03:59', 2, 1, '02/06/2017', 198, 'Yuri Paola', '2017-06-19 19:05:29', b'0', '0', b'0'),
(155, 'cpu amd atlon + monitor aoc', 200, 4, '2017-04-26', '2017-04-27', '', 220, 0, 137, b'0', b'0', '2017-04-26 16:42:52', 2, 1, '', 272, 'Yuri Paola', '2017-06-28 20:12:42', b'0', '0', b'0'),
(156, 'laptop hp', 300, 4, '2017-04-27', '2017-04-28', '', 330, 0, 138, b'0', b'0', '2017-04-27 09:54:04', 2, 1, '', 408, 'Yuri Paola', '2017-06-28 20:16:15', b'0', '0', b'0'),
(157, 'pc 4 con 2 monitor', 240, 4, '2017-04-27', '2017-04-28', '', 264, 0, 139, b'0', b'0', '2017-04-27 10:01:44', 2, 1, '', 326.4, 'Yuri Paola', '2017-06-28 20:15:48', b'0', '0', b'0'),
(158, 'microondas samsung cheff', 50, 4, '2017-04-27', '2017-04-28', '', 55, 0, 140, b'0', b'0', '2017-04-27 12:06:04', 2, 1, '', 68, 'Yuri Paola', '2017-06-28 20:11:48', b'0', '0', b'0'),
(159, 'guitarra electroacustica godin + calculadora hp 50g', 90, 4, '2017-04-27', '2017-04-28', '', 99, 0, 141, b'0', b'0', '2017-04-27 17:09:21', 2, 1, '', 104.4, 'Yuri Paola', '2017-05-25 12:43:59', b'0', '0', b'0'),
(160, 'estación total leica ts06 plush', 4000, 4, '2017-04-28', '2017-04-29', '', 4400, 0, 102, b'0', b'0', '2017-04-28 13:30:45', 2, 1, '', 4400, 'Yuri Paola', '2017-05-11 10:23:42', b'0', '0', b'0'),
(161, 'pedal soul food, pedal bluesky, balanza, amplificador', 300, 4, '2017-04-28', '2017-04-29', '', 330, 0, 142, b'0', b'0', '2017-04-28 14:50:03', 2, 1, '', 0, '', '', b'0', '0', b'0'),
(162, 'celular sony m4 aqua', 100, 4, '2017-04-28', '2017-04-29', '', 110, 0, 143, b'0', b'0', '2017-04-28 18:55:43', 2, 1, '', 110, 'Yuri Paola', '2017-05-11 10:24:10', b'0', '0', b'0'),
(163, 'una extractora y una computadora', 200, 4, '2017-04-29', '2017-04-30', '', 220, 0, 144, b'0', b'0', '2017-04-29 12:24:16', 2, 1, '', 312, 'Aumbbel', '2017-08-05 13:48:52', b'0', '0', b'0'),
(164, 'laptop hp i5 con estuche (sin cargador)', 250, 4, '2017-04-02', '2017-05-03', '', 275, 0, 70, b'0', b'0', '2017-05-02 09:20:19', 2, 1, '', 330, 'Yuri Paola', '2017-05-24 11:14:01', b'0', '0', b'0'),
(165, 'celular samsung j7', -20, 4, '2017-05-06', '2017-05-04', 'Se adelantó S/. 220.00 de S/. 200.00 el día 06/05/2017<br>', 220, 220, 145, b'0', b'0', '2017-05-03 14:26:13', 2, 1, '', 220, 'Mateo Quincho', '2017-05-27 10:33:49', b'0', '0', b'0'),
(166, 'mouse gamer', 50, 4, '2017-05-04', '2017-05-05', '', 55, 0, 54, b'0', b'0', '2017-05-04 13:43:19', 9, 2, '', 55, 'demo', '2017-05-10 12:24:27', b'0', '0', b'0'),
(167, 'cd de musica', 15, 4, '2017-05-04', '2017-05-05', '', 16.5, 0, 54, b'0', b'0', '2017-05-04 13:44:50', 9, 2, '', 16.5, '', '2017-05-04 18:02:16', b'0', '0', b'0'),
(168, 'laptop hp amd a8', 300, 4, '2017-05-08', '2017-05-09', '', 330, 0, 146, b'0', b'0', '2017-05-08 11:24:29', 2, 1, '', 330, 'Yuri Paola', '2017-05-15 10:21:10', b'0', '', b'0'),
(169, '2 laptop lenovo b40-80 corei3', 800, 4, '2017-07-10', '2017-05-09', 'Se canceló el interés S/. 96.00 de el día 10/07/2017<br>Se canceló el interés S/. 192.00 de el día 19/06/2017<br>', 880, 0, 147, b'0', b'1', '2017-05-08 14:43:09', 2, 1, '10/07/2017', 0, '', '', b'0', '', b'0'),
(170, 'laptop hp 14-am012la', 500, 4, '2017-05-09', '2017-05-10', '', 550, 0, 148, b'0', b'0', '2017-05-09 18:53:24', 2, 1, '', 560, 'Mateo Quincho', '2017-05-27 11:20:09', b'0', '', b'0'),
(171, 'celular s7 edge samsung', 500, 4, '2017-05-10', '2017-05-11', '', 550, 0, 149, b'0', b'0', '2017-05-10 17:17:11', 2, 1, '', 550, 'Yuri Paola', '2017-05-20 12:26:23', b'0', '', b'0'),
(172, 'celular abc', 15, 4, '2017-06-14', '2017-05-12', 'Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 3.60 de el día 14/06/2017<br>Se canceló el interés S/. 1.50 de el día 11/05/2017<br>Se canceló el interés S/. 16.50 de el día 11/05/2017<br>', 16.5, 0, 54, b'0', b'0', '2017-05-11 11:17:08', 9, 2, '14/06/2017', 16.5, 'demo', '2017-06-20 18:25:09', b'0', '', b'0'),
(173, 'laptop tosbiba satellite l755', 400, 4, '2017-05-11', '2017-05-12', '', 440, 0, 150, b'0', b'0', '2017-05-11 13:37:13', 2, 1, '', 512, 'Yuri Paola', '2017-06-28 20:18:20', b'0', '', b'0'),
(174, 'tv l 43\" 4k', 400, 4, '2017-05-11', '2017-05-12', '', 440, 0, 151, b'0', b'0', '2017-05-11 15:09:36', 2, 1, '', 608, 'Aumbbel', '2017-08-05 13:50:07', b'0', '', b'0'),
(175, 'mochila', 130, 4, '2017-06-20', '2017-05-12', 'Se adelantó S/. 20.00 de S/. 150.00 el día 20/06/2017<br>Se canceló el interés S/. 15.00 de el día 20/06/2017<br>Se canceló el interés S/. 30.00 de el día 14/06/2017<br>', 165, 20, 54, b'0', b'0', '2017-05-11 17:54:02', 9, 2, '20/06/2017', 143, 'demo', '2017-06-21 14:17:57', b'0', '', b'0'),
(176, 'pantalla vieja', 150, 4, '2017-05-11', '2017-05-12', 'Se canceló el interés S/. 15.00 de el día 15/05/2017<br>', 165, 0, 54, b'0', b'0', '2017-05-11 18:38:01', 9, 2, '15/05/2017', 186, 'demo', '2017-06-21 14:18:24', b'0', '', b'0'),
(177, 'estación total leica ts06 plush', 4500, 4, '2017-05-12', '2017-05-13', '', 4950, 0, 102, b'0', b'0', '2017-05-12 14:55:11', 2, 1, '', 5220, 'Yuri Paola', '2017-06-07 18:51:30', b'0', '', b'0'),
(178, 'samsung j7', 170, 4, '2017-05-12', '2017-05-13', '', 187, 0, 106, b'0', b'0', '2017-05-12 16:58:56', 2, 1, '', 187, 'Yuri Paola', '2017-05-22 13:02:14', b'0', '', b'0'),
(179, 'camara canon vixia', 250, 4, '2017-05-12', '2017-05-13', '', 275, 0, 152, b'0', b'0', '2017-05-12 17:32:41', 2, 1, '', 380, 'Aumbbel', '2017-08-05 13:50:26', b'0', '', b'0'),
(180, 'laptop compaq', 100, 4, '2017-05-12', '2017-05-13', '', 110, 0, 153, b'0', b'0', '2017-05-12 18:10:03', 2, 1, '', 128, '', '2017-06-27 16:42:40', b'0', '', b'0'),
(181, 'parlante amplicador', 350, 4, '2017-05-13', '2017-05-14', '', 385, 0, 154, b'0', b'0', '2017-05-13 12:56:26', 2, 1, '', 448, 'Yuri Paola', '2017-06-28 20:17:14', b'0', '', b'0'),
(182, 'laptop toshiba satellite l505', 300, 4, '2017-05-15', '2017-05-16', '', 330, 0, 155, b'0', b'0', '2017-05-15 09:44:20', 2, 1, '', 330, 'Yuri Paola', '2017-05-23 17:58:17', b'0', '', b'0'),
(183, 'tv smart lg 42lb5800', 400, 4, '2017-05-15', '2017-05-16', '', 440, 0, 156, b'0', b'0', '2017-05-15 12:25:44', 2, 1, '', 440, 'Yuri Paola', '2017-05-19 18:10:41', b'0', '', b'0'),
(184, 'laptop y40-70 lenovo con cargador y estuche', 300, 4, '2017-07-18', '2017-05-16', 'Se canceló el interés S/. 60.00 de el día 18/07/2017<br>Se adelantó S/. 300.00 de S/. 600.00 el día 19/06/2017<br>Se canceló el interés S/. 120.00 de el día 19/06/2017<br>', 660, 300, 157, b'0', b'0', '2017-05-15 17:26:59', 2, 1, '18/07/2017', 372, 'Yuri Paola', '2017-08-29 18:59:11', b'0', '', b'0'),
(185, 'laptop sony vaio i5', 200, 4, '2017-06-19', '2017-06-16', 'Se canceló el interés S/. 40.00 de el día 19/06/2017<br>', 240, 0, 158, b'0', b'0', '2017-05-16 14:44:46', 3, 1, '19/06/2017', 220, 'Yuri Paola', '2017-06-27 12:06:53', b'0', '', b'0'),
(186, 'laptop toshiba', 60, 4, '2017-05-17', '2017-05-25', '', 66, 0, 159, b'0', b'0', '2017-05-17 18:28:56', 3, 1, '', 86.4, 'Aumbbel', '2017-08-01 00:49:08', b'0', '', b'0'),
(187, 'lg xboom cm 8460', 600, 4, '2017-05-18', '2017-05-19', 'TOTALMENTE NUEVO SELLADO', 660, 0, 160, b'0', b'0', '2017-05-18 15:35:53', 2, 1, '', 864, 'Aumbbel', '2017-07-31 23:58:52', b'0', '', b'0'),
(188, 'ps2 sony y bluray sony', 200, 4, '2017-05-18', '2017-05-19', '', 220, 0, 161, b'0', b'0', '2017-05-18 16:05:05', 2, 1, '', 296, 'Aumbbel', '2017-08-05 13:50:45', b'0', '', b'0'),
(189, 'laptop hp pavilion 14', 250, 4, '2017-05-19', '2017-06-19', '', 300, 0, 59, b'0', b'0', '2017-05-19 11:30:52', 3, 1, '', 275, '', '2017-06-01 15:25:05', b'0', '', b'0'),
(190, 'televisor lg 47ln5400', 300, 4, '2017-05-19', '2017-06-19', '', 360, 0, 156, b'0', b'0', '2017-05-19 12:49:21', 3, 1, '', 330, 'Yuri Paola', '2017-05-22 16:53:16', b'0', '', b'0'),
(191, 'maquina soldar miller maxstar 200', 300, 4, '2017-05-19', '2017-06-19', '', 360, 0, 162, b'0', b'0', '2017-05-19 14:15:00', 3, 1, '', 360, 'Mateo Quincho', '2017-06-17 12:00:50', b'0', '', b'0'),
(192, 'moto pulsar 200 amarillo', 2500, 4, '2017-05-19', '2017-06-19', '', 3000, 0, 163, b'0', b'0', '2017-05-19 15:40:26', 3, 1, '', 2750, 'Yuri Paola', '2017-05-31 19:32:01', b'0', '', b'0'),
(193, 'laptop lenovo g50-45', 350, 4, '2017-05-19', '2017-06-19', '', 420, 0, 164, b'0', b'0', '2017-05-19 16:30:14', 3, 1, '', 385, 'Yuri Paola', '2017-05-29 17:33:06', b'0', '', b'0'),
(194, 'celulares (sony c5,samdung j5)', 300, 4, '2017-05-19', '2017-06-19', '', 360, 0, 91, b'0', b'0', '2017-05-19 17:08:42', 3, 1, '', 330, 'Yuri Paola', '2017-05-25 10:40:49', b'0', '', b'0'),
(195, 'tv led nex 32\"', 150, 4, '2017-05-20', '2017-05-21', '', 165, 0, 165, b'0', b'0', '2017-05-20 10:17:37', 3, 1, '', 186, 'Aumbbel', '2017-06-28 20:32:09', b'0', '', b'0'),
(196, 'laptop toshiba', 70, 4, '2017-05-20', '2017-05-21', '', 77, 0, 166, b'0', b'0', '2017-05-20 13:59:32', 3, 1, '', 100.8, 'Aumbbel', '2017-08-01 00:49:24', b'0', '', b'0'),
(197, 'laptop lenovo z51', 300, 4, '2017-07-06', '2017-06-22', 'Se canceló el interés S/. 84.00 de el día 06/07/2017<br>', 360, 0, 143, b'0', b'0', '2017-05-22 12:16:32', 3, 1, '06/07/2017', 372, 'Yuri Paola', '2017-08-15 11:28:47', b'0', '', b'0'),
(198, '2 estación total ...', 6000, 4, '2017-05-22', '2017-06-22', '', 7200, 0, 102, b'0', b'0', '2017-05-22 16:39:56', 3, 1, '', 8640, 'Yuri Paola', '2017-08-01 12:07:02', b'0', '', b'0'),
(199, 'teodolito topcon dt200+ nivel topcon+ campana de cocina', 1500, 4, '2017-08-16', '2017-06-22', 'Se canceló el interés S/. 300.00 de el día 16/08/2017<br>Se canceló el interés S/. 300.00 de el día 18/07/2017<br>Se canceló el interés S/. 240.00 de el día 19/06/2017<br>7 objetos ', 1800, 0, 167, b'0', b'1', '2017-05-22 18:13:17', 3, 1, '16/08/2017', 0, '', '', b'0', '', b'0'),
(200, 'tv aoc 19\"', 50, 4, '2017-05-22', '2017-06-22', '', 60, 0, 168, b'0', b'0', '2017-05-22 19:07:09', 3, 1, '', 55, '', '2017-05-29 17:31:05', b'0', '', b'0'),
(201, 'calculadora texas instruments nspire ti nspire cx.', 150, 4, '2017-09-19', '2017-06-23', '', 180, 0, 169, b'0', b'0', '2017-05-23 18:09:44', 3, 1, '19/09/2017', 0, '', '', b'0', '', b'0'),
(202, 'tablet samsung gt p7300', 100, 4, '2017-05-24', '2017-06-24', '', 120, 0, 170, b'0', b'0', '2017-05-24 14:50:47', 3, 1, '', 110, 'Yuri Paola', '2017-06-02 18:13:54', b'0', '', b'0'),
(203, 'demoledor master tools mt 90k', 200, 4, '2017-07-05', '2017-06-24', 'Se canceló el interés S/. 48.00 de el día 05/07/2017<br>', 240, 0, 171, b'0', b'1', '2017-05-24 15:04:50', 3, 1, '05/07/2017', 0, '', '', b'0', '', b'0'),
(204, 'pcu i5 + monitor lg 19\"', 200, 4, '2017-09-19', '2017-06-25', '', 240, 0, 149, b'0', b'0', '2017-05-25 16:47:11', 3, 1, '19/09/2017', 0, '', '', b'0', '', b'0'),
(205, 'laptop toshiba i3 + iphone 5c', 400, 4, '2017-05-25', '2017-06-25', '', 480, 0, 172, b'0', b'0', '2017-05-25 17:27:36', 3, 1, '', 512, 'Aumbbel', '2017-07-11 19:28:08', b'0', '', b'0'),
(206, 'tablet chuwi + mouse', 100, 4, '2017-05-25', '2017-06-25', '', 120, 0, 173, b'0', b'0', '2017-05-25 18:59:01', 3, 1, '', 124, '', '2017-07-03 17:27:27', b'0', '', b'0'),
(207, 'tv smart lg 42lb5800', 450, 4, '2017-05-26', '2017-06-26', '', 540, 0, 156, b'0', b'0', '2017-05-26 09:33:03', 3, 1, '', 495, 'Yuri Paola', '2017-05-29 18:08:13', b'0', '', b'0'),
(208, 'saxo hamaha yas 23', 500, 4, '2017-06-23', '2017-06-26', 'Se canceló el interés S/. 80.00 de el día 23/06/2017<br>', 600, 0, 174, b'0', b'0', '2017-05-26 10:29:05', 3, 1, '23/06/2017', 580, 'Yuri Paola', '2017-07-17 09:03:55', b'0', '', b'0'),
(209, 'guitarra electrica freeman', 50, 4, '2017-05-26', '2017-06-26', '', 60, 0, 175, b'0', b'0', '2017-05-26 15:40:53', 3, 1, '', 72, 'Aumbbel', '2017-08-05 13:51:41', b'0', '', b'0'),
(210, 'pc', 500, 4, '2017-05-27', '2017-05-28', '', 550, 0, 54, b'0', b'0', '2017-05-27 09:15:30', 9, 2, '', 550, 'demo', '2017-05-27 09:15:41', b'0', '', b'0'),
(211, 'juego de 5 ollas rena ware', 1000, 4, '2017-05-29', '2017-06-29', '', 1200, 0, 176, b'0', b'0', '2017-05-29 11:56:44', 3, 1, '', 1160, 'Pilar Maria', '2017-06-24 12:07:05', b'0', '', b'0'),
(212, 'estación total leica ts06 plush', 6000, 4, '2017-05-29', '2017-06-29', '', 7200, 0, 102, b'0', b'0', '2017-05-29 18:21:35', 3, 1, '', 6600, '', '2017-06-07 18:41:17', b'0', '', b'0'),
(213, 'pieza d emano de alta luz lez + celular lg k10', 100, 4, '2017-05-30', '2017-06-30', '', 120, 0, 177, b'0', b'0', '2017-05-30 09:26:58', 3, 1, '', 140, 'Aumbbel', '2017-08-05 13:52:15', b'0', '', b'0'),
(214, 'tv lg 32lh500b', 200, 4, '2017-05-30', '2017-06-30', '', 240, 0, 178, b'0', b'0', '2017-05-30 15:41:29', 3, 1, '', 280, 'Aumbbel', '2017-08-05 13:52:52', b'0', '', b'0'),
(215, 'hp todo en uno 20 b403la', 200, 4, '2017-05-30', '2017-06-30', '', 240, 0, 179, b'0', b'0', '2017-05-30 17:18:04', 3, 1, '', 220, 'Yuri Paola', '2017-06-06 17:43:35', b'0', '', b'0'),
(216, 'celular j7', 250, 4, '2017-05-30', '2017-06-30', '', 300, 0, 106, b'0', b'0', '2017-05-30 19:15:08', 3, 1, '', 280, 'Yuri Paola', '2017-06-15 09:43:14', b'0', '', b'0'),
(217, 'ps 3 con 1 mando y cables', 200, 4, '2017-06-02', '2017-07-02', '', 240, 0, 180, b'0', b'0', '2017-06-02 10:18:34', 3, 1, '', 224, 'Yuri Paola', '2017-06-23 18:58:39', b'0', '', b'0'),
(218, 'laptop lenovo b40-80', 300, 4, '2017-06-02', '2017-07-02', '', 360, 0, 68, b'0', b'0', '2017-06-02 13:09:13', 3, 1, '', 360, 'Yuri Paola', '2017-07-05 09:42:23', b'0', '', b'0'),
(219, 'taladro 20v dewalt dcd776-026022', 150, 4, '2017-06-18', '2017-07-02', 'Se canceló el interés S/. 18.00 de el día 18/06/2017<br>', 180, 0, 181, b'0', b'0', '2017-06-02 17:54:37', 3, 1, '18/06/2017', 168, 'Manrique', '2017-06-18 14:12:05', b'0', '', b'0'),
(220, 'calculadora hp g50+audifono sony+dni+celular xperia', 200, 4, '2017-06-02', '2017-07-02', '', 240, 0, 182, b'0', b'0', '2017-06-02 18:11:22', 3, 1, '', 240, '', '2017-07-06 13:23:33', b'0', '', b'0'),
(221, 'celular samsung j5', 180, 4, '2017-06-03', '2017-06-04', '', 198, 0, 183, b'0', b'0', '2017-06-03 11:49:01', 12, 1, '', 198, '', '2017-06-12 16:40:41', b'0', '', b'0'),
(222, 'televisor  lg smart 42\"', 350, 4, '2017-06-03', '2017-06-04', 'CONTROL ', 385, 0, 104, b'0', b'0', '2017-06-03 12:16:19', 12, 1, '', 476, 'Aumbbel', '2017-08-05 13:53:52', b'0', '', b'0'),
(223, 'tv lg 42lb65', 400, 4, '2017-08-07', '2017-07-05', 'Se canceló el interés S/. 80.00 de el día 07/08/2017<br>Se canceló el interés S/. 80.00 de el día 05/07/2017<br>', 480, 0, 184, b'0', b'0', '2017-06-05 10:50:27', 3, 1, '07/08/2017', 496, 'Yuri Paola', '2017-09-12 13:13:36', b'0', '', b'0'),
(224, 'laptop compaq amd', 200, 4, '2017-06-05', '2017-07-05', '', 240, 0, 185, b'0', b'0', '2017-06-05 11:50:28', 3, 1, '', 272, 'Aumbbel', '2017-08-01 00:50:16', b'0', '', b'0'),
(225, 'impresora + maquina de ejercicio', 120, 4, '2017-06-05', '2017-07-05', '', 144, 0, 186, b'0', b'0', '2017-06-05 12:17:00', 3, 1, '', 148.8, 'Yuri Paola', '2017-07-11 10:17:04', b'0', '', b'0'),
(226, 'laptop hp envy dv6 notebook pc', 350, 4, '2017-06-05', '2017-07-05', '', 420, 0, 187, b'0', b'0', '2017-06-05 15:11:28', 3, 1, '', 385, 'Yuri Paola', '2017-06-13 17:35:35', b'0', '', b'0'),
(227, 'celular zte blade l5', 70, 4, '2017-06-05', '2017-07-05', '', 84, 0, 188, b'0', b'0', '2017-06-05 17:22:02', 3, 1, '', 78.4, '', '2017-06-26 17:35:04', b'0', '', b'0'),
(228, 'camara+cargador+estuche', 50, 4, '2017-06-05', '2017-07-05', '', 60, 0, 189, b'0', b'0', '2017-06-05 18:31:09', 3, 1, '', 55, '', '2017-06-19 14:47:26', b'0', '', b'0'),
(229, 'auto kia rio placa w2z-360', 3200, 4, '2017-06-05', '2017-06-19', '', 3520, 0, 190, b'0', b'0', '2017-06-05 18:47:18', 3, 1, '', 3520, 'Yuri Paola', '2017-06-14 18:22:29', b'0', '', b'0'),
(230, 'celular samsung galaxy j2', 150, 4, '2017-06-06', '2017-07-06', '', 180, 0, 112, b'0', b'0', '2017-06-06 14:24:55', 3, 1, '', 174, '', '2017-07-04 18:01:37', b'0', '', b'0'),
(231, 'tv. sony kdl 40w605b', 300, 4, '2017-06-06', '2017-07-06', '', 360, 0, 191, b'0', b'0', '2017-06-06 16:05:21', 3, 1, '', 408, 'Aumbbel', '2017-08-05 13:54:21', b'0', '', b'0'),
(232, 'tv smart lg 42lb5800', 450, 4, '2017-06-07', '2017-07-07', '', 540, 0, 156, b'0', b'0', '2017-06-07 18:04:01', 3, 1, '', 495, '', '2017-06-13 18:30:08', b'0', '', b'0'),
(233, 'estacion total sokkia cx-105', 8000, 4, '2017-05-29', '2017-06-07', '', 8800, 0, 102, b'0', b'0', '2017-06-07 18:47:14', 3, 1, '', 11200, 'Yuri Paola', '2017-08-01 12:07:19', b'0', '', b'0'),
(234, 'gps garmin oregon 650', 450, 4, '2017-06-07', '2017-07-07', '', 540, 0, 102, b'0', b'0', '2017-06-07 18:56:53', 3, 1, '', 594, 'Yuri Paola', '2017-08-01 12:05:57', b'0', '', b'0'),
(235, 'equipo de sonido 7 parlantes panasonic + celular huawei lua u03', 450, 4, '2017-06-08', '2017-07-08', '', 540, 0, 192, b'0', b'0', '2017-06-08 10:45:43', 3, 1, '', 495, 'Yuri Paola', '2017-06-08 11:19:24', b'0', '', b'0'),
(236, 'equipo de sonido 7 parlantes panasonic + celular huawei lua u03', 300, 4, '2017-06-08', '2017-07-08', '', 360, 0, 192, b'0', b'0', '2017-06-08 11:20:13', 3, 1, '', 408, 'Aumbbel', '2017-08-05 13:55:07', b'0', '', b'0'),
(237, 'celular lg x screen', 100, 4, '2017-06-08', '2017-07-08', '', 120, 0, 193, b'0', b'0', '2017-06-08 13:11:20', 3, 1, '', 110, 'Yuri Paola', '2017-06-20 15:44:28', b'0', '', b'0'),
(238, '2 guitarras+ps2 con tres mandos+dos timon+teclado', 300, 4, '2017-09-14', '2017-07-08', 'Se canceló el interés S/. 48.00 de el día 14/09/2017<br>Se canceló el interés S/. 60.00 de el día 17/08/2017<br>Se canceló el interés S/. 36.00 de el día 17/07/2017<br>Se canceló el interés S/. 36.00 de el día 29/06/2017<br>', 360, 0, 194, b'0', b'1', '2017-06-08 17:34:34', 3, 1, '14/09/2017', 0, '', '', b'0', '', b'0'),
(239, 'cpu', 40, 4, '2017-06-09', '2017-06-10', '', 44, 0, 195, b'0', b'0', '2017-06-09 14:01:01', 12, 1, '', 46.4, 'manrique Mendoza', '2017-07-07 13:48:54', b'0', '', b'0'),
(240, 'detector de metales y detector de bullyser', 800, 4, '2017-06-09', '2017-06-10', '', 880, 0, 196, b'0', b'0', '2017-06-09 14:38:29', 12, 1, '', 1184, 'Aumbbel', '2017-08-30 13:11:03', b'0', '', b'0'),
(241, 'celular lg spidit', 60, 4, '2017-06-10', '2017-07-10', '', 72, 0, 197, b'0', b'0', '2017-06-12 09:37:51', 3, 1, '', 66, 'Yuri Paola', '2017-06-22 12:34:58', b'0', '', b'0'),
(242, 'roto martillo percutor kd975ka-b2c', 100, 4, '2017-06-18', '2017-07-10', 'Se canceló el interés S/. 10.00 de el día 18/06/2017<br>', 120, 0, 188, b'0', b'0', '2017-06-12 09:39:53', 3, 1, '18/06/2017', 110, 'Manrique', '2017-06-18 14:11:23', b'0', '', b'0'),
(243, 'moto negro smaach125', 400, 4, '2017-06-10', '2017-07-10', '', 480, 0, 198, b'0', b'0', '2017-06-12 09:51:42', 3, 1, '', 528, 'Yuri Paola', '2017-08-05 11:56:58', b'0', '', b'0'),
(244, 'celular lg k8', 80, 4, '2017-06-12', '2017-07-12', '', 96, 0, 197, b'0', b'0', '2017-06-12 10:00:16', 3, 1, '', 88, '', '2017-06-22 12:34:23', b'0', '', b'0'),
(245, 'carro kia rio rojo', 4100, 4, '2017-06-12', '2017-06-19', '', 4510, 0, 190, b'0', b'0', '2017-06-12 18:52:55', 3, 1, '', 4510, 'Yuri Paola', '2017-06-14 18:23:07', b'0', '', b'0');
INSERT INTO `producto` (`idProducto`, `prodNombre`, `prodMontoEntregado`, `prodInteres`, `prodFechaInicial`, `prodFechaVencimiento`, `prodObservaciones`, `prodMontoPagar`, `prodAdelanto`, `idCliente`, `prodDioAdelanto`, `prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal`, `prodUltimaFechaInteres`, `prodCuantoFinaliza`, `prodQuienFinaliza`, `prodFechaFinaliza`, `prodAprobado`, `prodQuienAprueba`, `esCompra`) VALUES
(246, 'tablet ipad md369e/a', 170, 4, '2017-06-13', '2017-07-07', '', 197.2, 0, 199, b'0', b'0', '2017-06-13 10:43:05', 3, 1, '', 187, 'Yuri Paola', '2017-06-27 10:25:43', b'0', '', b'0'),
(247, 'celular huawei vns l23', 150, 4, '2017-06-13', '2017-07-13', '', 180, 0, 200, b'0', b'0', '2017-06-13 11:02:18', 3, 1, '', 165, 'Yuri Paola', '2017-06-14 10:44:05', b'0', '', b'0'),
(248, 'guitarra acústica + celular azumi', 50, 4, '2017-07-17', '2017-07-13', 'Se canceló el interés S/. 10.00 de el día 17/07/2017<br>', 60, 0, 201, b'0', b'1', '2017-06-13 16:25:50', 3, 1, '17/07/2017', 0, '', '', b'0', '', b'0'),
(249, 'tv smart lg 42lb5800', 450, 4, '2017-06-13', '2017-07-13', '', 540, 0, 156, b'0', b'0', '2017-06-13 18:31:21', 3, 1, '', 495, 'Yuri Paola', '2017-06-16 17:43:31', b'0', '', b'0'),
(251, 'estacion total topcon cygnus ks-102', 4000, 4, '2017-06-14', '2017-07-14', '', 4800, 0, 202, b'0', b'0', '2017-06-14 11:37:24', 3, 1, '', 5120, 'Yuri Paola', '2017-08-01 12:08:16', b'0', '', b'0'),
(252, 'monitor aoc e960s', 50, 4, '2017-06-14', '2017-07-14', '', 60, 0, 195, b'0', b'0', '2017-06-14 17:06:36', 3, 1, '', 58, 'manrique Mendoza', '2017-07-07 13:47:41', b'0', '', b'0'),
(253, 'tv lg 49uh6030', 600, 4, '2017-07-10', '2017-07-15', 'Se canceló el interés S/. 96.00 de el día 10/07/2017<br>', 720, 0, 106, b'0', b'0', '2017-06-15 09:44:33', 3, 1, '10/07/2017', 672, 'Yuri Paola', '2017-07-31 09:47:03', b'0', '', b'0'),
(254, 'laptop samsung basico', 150, 4, '2017-06-15', '2017-07-15', '', 180, 0, 203, b'0', b'0', '2017-06-15 11:27:05', 3, 1, '', 165, 'Yuri Paola', '2017-06-19 12:46:24', b'0', '', b'0'),
(255, 'moto rojo con blanco sunshine', 600, 4, '2017-06-15', '2017-07-15', '', 720, 0, 204, b'0', b'0', '2017-06-15 12:41:47', 3, 1, '', 696, 'Yuri Paola', '2017-07-12 13:24:10', b'0', '', b'0'),
(256, 'laptop hp basico', 228, 4, '2017-07-22', '2017-07-15', 'Se adelantó S/. 72.00 de S/. 300.00 el día 22/07/2017<br>', 360, 72, 205, b'0', b'1', '2017-06-15 12:50:49', 3, 1, '', 0, '', '', b'0', '', b'0'),
(257, 'laptop toshiba corei3 4ta generacion', 330, 4, '2017-06-15', '2017-07-15', 'MALETIN Y CALCULADORA Y CARGADOR', 396, 0, 206, b'0', b'0', '2017-06-15 17:08:38', 13, 1, '', 363, '', '2017-06-27 14:45:02', b'0', '', b'0'),
(258, 'televisor lg 49uh65', 400, 4, '2017-06-16', '2017-07-16', '', 480, 0, 207, b'0', b'0', '2017-06-16 09:52:43', 3, 1, '', 448, 'manrique Mendoza', '2017-07-07 17:51:40', b'0', '', b'0'),
(259, 'laptop hp amd a8 con cargador', 300, 4, '2017-06-16', '2017-07-16', 'estuche hello kitty ', 360, 0, 146, b'0', b'0', '2017-06-16 10:42:30', 3, 1, '', 384, 'Aumbbel', '2017-08-01 01:26:00', b'0', '', b'0'),
(260, 'tv 3d smart samsung 40 6400', 400, 4, '2017-09-19', '2017-07-16', '', 480, 0, 48, b'0', b'0', '2017-06-16 11:06:37', 3, 1, '19/09/2017', 0, '', '', b'0', '', b'0'),
(261, 'celular moto x play', 150, 4, '2017-06-16', '2017-07-16', '', 180, 0, 208, b'0', b'0', '2017-06-16 11:24:23', 3, 1, '', 174, '', '2017-07-10 15:28:41', b'0', '', b'0'),
(262, 'celular iphone 7 en caja', 500, 4, '2017-06-16', '2017-07-16', '', 600, 0, 209, b'0', b'0', '2017-06-16 17:14:49', 3, 1, '', 550, '', '2017-06-26 18:21:50', b'0', '', b'0'),
(263, 'tv lg 29\" + celar sony xperia', 400, 4, '2017-06-19', '2017-07-19', '', 480, 0, 210, b'0', b'0', '2017-06-19 19:31:54', 3, 1, '', 464, 'Yuri Paola', '2017-07-12 09:51:25', b'0', '', b'0'),
(264, 'tv sony mas control', 350, 4, '2017-06-19', '2017-08-19', 'tv sony mas control', 476, 0, 211, b'0', b'0', '2017-06-19 20:18:15', 13, 1, '', 406, 'Yuri Paola', '2017-07-13 16:02:19', b'0', '', b'0'),
(265, 'tv smart lg 42lb5800', 450, 4, '2017-06-28', '2017-07-20', 'Se canceló el interés S/. 45.00 de el día 28/06/2017<br>', 540, 0, 156, b'0', b'0', '2017-06-20 10:26:49', 3, 1, '28/06/2017', 495, 'Yuri Paola', '2017-06-28 18:42:26', b'0', '', b'0'),
(266, 'taladro bauker', 30, 4, '2017-06-21', '2017-07-21', '', 36, 0, 212, b'0', b'0', '2017-06-21 10:55:53', 3, 1, '', 42, 'Aumbbel', '2017-08-30 13:30:08', b'0', '', b'0'),
(267, 'cd antiguo', 150, 4, '2017-06-21', '2017-06-22', '', 165, 0, 54, b'0', b'0', '2017-06-21 14:06:52', 9, 2, '', 165, 'demo', '2017-06-21 14:17:37', b'0', '', b'0'),
(268, 'cd antiguo', 136, 4, '2017-06-21', '2017-06-22', 'Se canceló el interés S/. 0.00 de el día 21/06/2017<br>Se canceló el interés S/. 0.00 de el día 21/06/2017<br>Se canceló el interés S/. 13.60 de el día 21/06/2017<br>Se canceló el interés S/. 0.00 de el día 21/06/2017<br>Se canceló el interés S/. 0.00 de el día 21/06/2017<br>Se canceló el interés S/. 0.00 de el día 21/06/2017<br>Se canceló el interés S/. 13.60 de el día 21/06/2017<br>Se canceló el interés S/. 13.60 de el día 21/06/2017<br>Se adelantó S/. 14.00 de S/. 150.00 el día 21/06/2017<br>', 165, 14, 54, b'0', b'0', '2017-06-21 14:29:41', 9, 2, '21/06/2017', 136, 'demo', '2017-06-21 17:46:47', b'0', '', b'0'),
(269, 'producto de prueba', 55, 4, '2017-06-21', '2017-06-22', '', 60.5, 0, 54, b'0', b'0', '2017-06-21 14:42:05', 9, 2, '', 60.5, 'demo', '2017-06-21 15:11:27', b'0', '', b'0'),
(270, 'prueba', 20, 4, '2017-06-21', '2017-06-22', 'Se adelantó S/. 4.50 de S/. 24.50 el día 21/06/2017<br>Se adelantó S/. 6.50 de S/. 31.00 el día 21/06/2017<br>Se adelantó S/. 4.00 de S/. 35.00 el día 21/06/2017<br>Se adelantó S/. 9.00 de S/. 44.00 el día 21/06/2017<br>Se adelantó S/. 8.00 de S/. 52.00 el día 21/06/2017<br>Se adelantó S/. 8.00 de S/. 60.00 el día 21/06/2017<br>Se adelantó S/. 9.00 de S/. 69.00 el día 21/06/2017<br>Se adelantó S/. 1.00 de S/. 70.00 el día 21/06/2017<br>Se adelantó S/. 5.00 de S/. 75.00 el día 21/06/2017<br>Se adelantó S/. 5.00 de S/. 80.00 el día 21/06/2017<br>Se adelantó S/. 5.00 de S/. 85.00 el día 21/06/2017<br>Se adelantó S/. 15.00 de S/. 100.00 el día 21/06/2017<br>Se adelantó S/. 9.00 de S/. 109.00 el día 21/06/2017<br>Se canceló el interés S/. 10.90 de el día 21/06/2017<br>Se canceló el interés S/. 11.00 de el día 21/06/2017<br>Se canceló el interés S/. 11.00 de el día 21/06/2017<br>', 121, 89, 54, b'0', b'0', '2017-06-21 16:55:04', 9, 2, '21/06/2017', 20, 'demo', '2017-06-21 17:43:35', b'0', '', b'0'),
(271, 'libro nuevo', 15, 4, '2017-06-21', '2017-06-22', '', 16.5, 0, 54, b'0', b'0', '2017-06-21 17:48:24', 9, 2, '', 16.5, 'demo', '2017-06-21 17:48:29', b'0', '', b'0'),
(272, 'moto  advance', 400, 4, '2017-06-22', '2017-07-22', '', 480, 0, 213, b'0', b'0', '2017-06-22 10:27:58', 3, 1, '', 464, 'Yuri Paola', '2017-07-14 13:48:46', b'0', '', b'0'),
(273, 'motocicleta hero passion pro tr', 800, 4, '2017-07-20', '2017-07-22', 'Se canceló el interés S/. 128.00 de el día 20/07/2017<br>', 960, 0, 214, b'0', b'0', '2017-06-22 13:36:39', 3, 1, '20/07/2017', 896, 'Yuri Paola', '2017-08-08 11:17:06', b'0', '', b'0'),
(274, 'laptop hp envy dv6 notebook pc', 400, 4, '2017-06-23', '2017-07-23', '', 480, 0, 187, b'0', b'1', '2017-06-23 15:19:30', 3, 1, '', 0, '', '', b'0', '', b'0'),
(275, 'cpu+teclado+monitor samsung', 90, 4, '2017-06-23', '2017-07-23', '', 108, 0, 215, b'0', b'1', '2017-06-23 16:23:03', 3, 1, '', 0, '', '', b'0', '', b'0'),
(276, 'todo en uno lenovo amd e540', 400, 4, '2017-08-28', '2017-07-23', 'Se canceló el interés S/. 80.00 de el día 28/08/2017<br>Se canceló el interés S/. 80.00 de el día 24/07/2017<br>', 480, 0, 216, b'0', b'1', '2017-06-23 16:44:51', 3, 1, '28/08/2017', 0, '', '', b'0', '', b'0'),
(277, 'celular sony xperia', 80, 4, '2017-06-23', '2017-07-23', '', 96, 0, 182, b'0', b'1', '2017-06-23 18:35:02', 3, 1, '', 0, '', '', b'0', '', b'0'),
(278, 'agregar a las estaciones', 500, 4, '2017-06-23', '2017-07-23', '', 600, 0, 202, b'0', b'0', '2017-06-23 19:26:31', 3, 1, '', 620, 'Yuri Paola', '2017-08-01 12:07:58', b'0', '', b'0'),
(279, 'tablet', 200, 4, '2017-06-23', '2017-06-30', 'TABLET MAS CARGADOR', 220, 0, 217, b'0', b'0', '2017-06-24 09:58:09', 13, 1, '', 220, 'Yuri Paola', '2017-07-04 17:01:09', b'0', '', b'0'),
(280, 'laptop toshiba corei7', 600, 4, '2017-06-23', '2017-07-23', 'MOCHILA CARGADOR MOUSE LAPTOP', 720, 0, 218, b'0', b'0', '2017-06-24 10:01:19', 13, 1, '', 672, 'Yuri Paola', '2017-07-14 10:39:25', b'0', '', b'0'),
(281, 'laptop toshiba', 200, 4, '2017-08-22', '2017-06-25', 'Se canceló el interés S/. 40.00 de el día 22/08/2017<br>Se canceló el interés S/. 32.00 de el día 21/07/2017<br>CON CARGADOR', 220, 0, 219, b'0', b'1', '2017-06-24 11:47:31', 12, 1, '22/08/2017', 0, '', '', b'0', '', b'0'),
(282, 'televisor lg 47ln5400', 300, 4, '2017-06-26', '2017-07-26', '', 360, 0, 156, b'0', b'0', '2017-06-26 09:51:12', 3, 1, '', 330, 'Yuri Paola', '2017-06-28 18:42:47', b'0', '', b'0'),
(283, 'dewalt dcb107', 100, 4, '2017-06-26', '2017-07-26', '', 120, 0, 188, b'0', b'0', '2017-06-26 17:40:20', 3, 1, '', 120, 'Yuri Paola', '2017-07-31 21:10:58', b'0', '', b'0'),
(284, 'tablet samsung', 150, 4, '2017-06-24', '2017-07-24', 'tablet mas Cargador', 180, 0, 170, b'0', b'1', '2017-06-26 20:08:10', 13, 1, '', 0, '', '', b'0', '', b'0'),
(285, 'laptop toshiba', 70, 4, '2017-06-24', '2017-07-24', 'TOSHIBA AMD', 84, 0, 220, b'0', b'0', '2017-06-26 20:10:39', 13, 1, '', 81.2, 'Yuri Paola', '2017-07-18 13:46:40', b'0', '', b'0'),
(286, 'auto toyora yaris', 10000, 4, '2017-07-25', '2017-07-27', 'Se canceló el interés S/. 1600.00 de el día 25/07/2017<br>', 12000, 0, 221, b'0', b'0', '2017-06-27 13:25:31', 3, 1, '25/07/2017', 11000, 'Aumbbel', '2017-07-31 23:53:21', b'0', '', b'0'),
(287, 'celular lg x style', 100, 4, '2017-06-28', '2017-07-28', '', 120, 0, 209, b'0', b'0', '2017-06-28 16:09:58', 3, 1, '', 110, 'Pilar Maria', '2017-07-01 11:07:47', b'0', '', b'0'),
(288, 'moto rojo con blanco sunshine', 600, 4, '2017-07-12', '2017-07-28', 'Se canceló el interés S/. 60.00 de el día 12/07/2017<br>', 720, 0, 204, b'0', b'0', '2017-06-28 17:44:34', 3, 1, '12/07/2017', 660, '', '2017-07-21 12:54:06', b'0', '', b'0'),
(289, 'samsung celular j7', 250, 4, '2017-06-30', '2017-07-30', 'solo celular', 300, 0, 222, b'0', b'1', '2017-06-30 15:48:40', 13, 1, '', 0, '', '', b'0', '', b'0'),
(290, 'toshiba corei5 satelitall', 210, 4, '2017-06-30', '2017-07-30', 'laptop mas cargador', 252, 0, 223, b'0', b'0', '2017-06-30 15:50:59', 13, 1, '', 235.2, 'Yuri Paola', '2017-07-20 12:13:02', b'0', '', b'0'),
(291, 'equipo de sonido sony ss wgr88p', 250, 4, '2017-06-30', '2017-07-30', '', 300, 0, 224, b'0', b'0', '2017-06-30 17:31:11', 3, 1, '', 300, 'Yuri Paola', '2017-07-31 15:08:43', b'0', '', b'0'),
(292, 'moto bajaj pulsar + celular sony xperia', 1300, 4, '2017-06-30', '2017-07-30', '', 1560, 0, 225, b'0', b'0', '2017-06-30 18:18:37', 3, 1, '', 1430, 'Beatriz', '2017-07-05 19:16:07', b'0', '', b'0'),
(293, 'equipo de odontologia', 2000, 4, '2017-06-30', '2017-07-15', 'Se canceló el interés S/. 240.00 de el día 30/06/2017<br>', 2400, 0, 226, b'0', b'1', '2017-06-30 19:37:53', 3, 1, '30/06/2017', 0, '', '', b'0', '', b'0'),
(294, 'laptop advance', 250, 4, '2017-07-01', '2017-07-02', 'CARGADOR ', 275, 0, 227, b'0', b'0', '2017-07-01 13:39:02', 12, 1, '', 275, 'Yuri Paola', '2017-07-03 15:49:01', b'0', '', b'0'),
(295, 'taladro radio celular lg', 220, 4, '2017-07-01', '2017-07-02', '', 242, 0, 228, b'0', b'1', '2017-07-01 14:23:38', 12, 1, '', 0, '', '', b'0', '', b'0'),
(296, 'televisor lg 42lb5610 + microondas ms1140s', 350, 4, '2017-07-03', '2017-08-03', '', 420, 0, 229, b'0', b'0', '2017-07-03 10:57:34', 3, 1, '', 406, 'Beatriz', '2017-07-27 12:48:47', b'0', '', b'0'),
(297, 'celular g4', 150, 4, '2017-07-03', '2017-08-03', '', 180, 0, 230, b'0', b'1', '2017-07-03 14:41:54', 3, 1, '', 0, '', '', b'0', '', b'0'),
(298, 'nivele + 2 radios', 600, 4, '2017-06-09', '2017-07-09', '', 720, 0, 102, b'0', b'0', '2017-07-03 16:40:03', 3, 1, '', 792, 'Yuri Paola', '2017-08-01 12:06:29', b'0', '', b'0'),
(299, 'bombones', 443, 4, '2017-07-03', '2017-07-04', 'Se canceló el interés S/. 44.30 de el día 03/07/2017<br>', 487.3, 0, 54, b'0', b'0', '2017-07-03 19:18:29', 9, 2, '03/07/2017', 443, 'demo', '2017-07-03 19:19:27', b'0', '', b'0'),
(300, 'tv smart lg 42lb5800 + televisor lg 47ln5400', 750, 4, '2017-07-04', '2017-08-04', '', 900, 0, 156, b'0', b'0', '2017-07-04 09:58:39', 3, 1, '', 840, '', '2017-07-21 17:29:36', b'0', '', b'0'),
(301, 'laptop vaio hp color plomo con cargador', 200, 4, '2017-07-04', '2017-08-04', '', 240, 0, 231, b'0', b'0', '2017-07-04 11:54:25', 3, 1, '', 232, 'Beatriz', '2017-07-27 17:16:53', b'0', '', b'0'),
(302, 'smartwacht , camara digital samsung', 60, 4, '2017-07-01', '2017-08-01', '', 72, 0, 232, b'0', b'0', '2017-07-04 12:20:12', 13, 1, '', 66, 'Beatriz', '2017-07-15 17:36:08', b'0', '', b'0'),
(303, 'moto lineal pulsar  5251-1w', 1300, 4, '2017-07-01', '2017-08-01', 'docs y moto casco', 1560, 0, 233, b'0', b'0', '2017-07-04 12:23:30', 13, 1, '', 1664, '', '2017-08-14 15:17:34', b'0', '', b'0'),
(304, 'celular samsung galaxy j2', 150, 4, '2017-07-04', '2017-08-04', '', 180, 0, 234, b'0', b'1', '2017-07-04 18:12:36', 3, 1, '', 0, '', '', b'0', '', b'0'),
(305, 'licuadora rena ware', 700, 4, '2017-08-04', '2017-08-05', 'Se canceló el interés S/. 140.00 de el día 04/08/2017<br>', 840, 0, 235, b'0', b'1', '2017-07-05 17:43:32', 3, 1, '04/08/2017', 0, '', '', b'0', '', b'0'),
(306, 'piano yamaha', 200, 4, '2017-07-05', '2017-08-05', 'piano costal', 240, 0, 236, b'0', b'0', '2017-07-05 21:09:13', 13, 1, '', 288, 'Beatriz', '2017-09-14 21:40:23', b'0', '', b'0'),
(307, 'plancha thomas + moto3g', 230, 4, '2017-07-05', '2017-08-05', '', 276, 0, 237, b'0', b'0', '2017-07-05 21:11:58', 13, 1, '', 312.8, 'Aumbbel', '2017-09-05 17:19:05', b'0', '', b'0'),
(308, 'celular de prueba', 500, 4, '2017-06-23', '2017-07-08', '', 560, 0, 54, b'0', b'0', '2017-07-07 12:09:14', 9, 2, '', 560, 'demo', '2017-07-12 17:05:58', b'0', '', b'0'),
(309, 'laptop hp 240 g1', 104.4, 4, '2017-07-07', '2017-08-07', 'Dejó la laptop como pago del interés generado por sus 2 Artículos empeñados anteriormente ( monitor aoC E960 S/.48 y cpu micronics S/. 56.4 )', 125.28, 0, 238, b'0', b'1', '2017-07-07 14:07:54', 14, 1, '', 0, '', '', b'0', '', b'0'),
(310, 'guitarra eléctrica jt 690 -fr', 280, 4, '2017-07-08', '2017-07-09', '', 308, 0, 121, b'0', b'0', '2017-07-08 12:33:01', 12, 1, '', 358.4, 'Yuri Paola', '2017-08-25 17:31:45', b'0', '', b'0'),
(311, 'home theater bh5140s, bluray lg bp140, orbitrek, abcoaster', 450, 4, '2017-07-21', '2017-08-10', 'Se canceló el interés S/. 45.00 de el día 21/07/2017<br>', 540, 0, 156, b'0', b'0', '2017-07-10 10:39:28', 3, 1, '21/07/2017', 450, 'Yuri Paola', '2017-07-21 17:30:34', b'0', '', b'0'),
(312, 'taladro bauker id550e3 kit 50', 40, 4, '2017-07-10', '2017-08-10', '', 48, 0, 239, b'0', b'1', '2017-07-10 10:49:27', 3, 1, '', 0, '', '', b'0', '', b'0'),
(313, 'chocolatera renaware, filtro renaware, 2 licuadoras, una cocina repsol de mesa.', 1000, 4, '2017-07-11', '2017-08-11', 'Solo al 10%', 1200, 0, 240, b'0', b'0', '2017-07-11 11:24:29', 8, 3, '', 1280, 'Aumbbel', '2017-08-25 09:29:11', b'0', '', b'0'),
(314, 'guitarra electrica vozzex expresate', 80, 4, '2017-07-12', '2017-08-12', '', 96, 0, 241, b'0', b'0', '2017-07-12 14:39:33', 3, 1, '', 88, 'Beatriz', '2017-07-24 10:44:34', b'0', '', b'0'),
(315, 'celulares (sony c5,samdung j5) + extractora rena ware', 500, 4, '2017-07-12', '2017-08-12', '', 600, 0, 191, b'0', b'0', '2017-07-12 16:32:33', 3, 1, '', 600, 'Yuri Paola', '2017-08-16 10:02:48', b'0', '', b'0'),
(316, 'camara', 150, 4, '2017-09-20', '2017-07-13', '', 165, 0, 54, b'0', b'0', '2017-06-12 17:05:02', 9, 2, '20/09/2017', 165, 'demo', '2017-07-12 17:05:12', b'0', '', b'0'),
(317, 'celular demo', 120, 4, '2017-07-12', '2017-07-13', '', 132, 0, 54, b'0', b'0', '2017-07-12 18:45:48', 9, 2, '', 132, 'demo', '2017-07-12 18:45:57', b'0', '', b'0'),
(318, 'laptop toshiba i3 con calculadora en maleta', 400, 4, '2017-07-14', '2017-08-14', '', 480, 0, 206, b'0', b'0', '2017-07-14 15:04:12', 3, 1, '', 448, '', '2017-08-02 15:46:14', b'0', '', b'0'),
(319, '4 perfumes', 70, 4, '2017-09-14', '2017-07-16', 'Se canceló el interés S/. 25.20 de el día 14/09/2017<br>', 77, 0, 242, b'0', b'1', '2017-07-15 11:28:41', 12, 1, '14/09/2017', 0, '', '', b'0', '', b'0'),
(320, 'moto advance', 500, 4, '2017-07-16', '2017-08-17', '', 600, 0, 213, b'0', b'0', '2017-07-17 11:58:58', 13, 1, '', 620, 'Yuri Paola', '2017-08-21 10:36:37', b'0', '', b'0'),
(321, 'pcu+monitor+teclado+mouse+ 2 cables', 200, 4, '2017-06-07', '2017-07-07', '', 240, 0, 188, b'0', b'0', '2017-07-17 20:10:07', 3, 1, '', 248, 'Yuri Paola', '2017-07-17 20:10:18', b'0', '', b'0'),
(322, 'cpu antryx', 100, 4, '2017-09-14', '2017-08-18', 'Se canceló el interés S/. 36.00 de el día 14/09/2017<br>', 120, 0, 242, b'0', b'1', '2017-07-18 19:35:23', 3, 1, '14/09/2017', 0, '', '', b'0', '', b'0'),
(323, 'laptop hp', 300, 4, '2017-07-19', '2017-08-19', '', 360, 0, 47, b'0', b'0', '2017-07-19 10:35:59', 3, 1, '', 360, 'Aumbbel', '2017-08-19 20:04:32', b'0', '', b'0'),
(324, 'celular s6 edge', 200, 4, '2017-07-19', '2017-08-19', '', 240, 0, 243, b'0', b'0', '2017-07-19 17:52:26', 3, 1, '', 240, 'Aumbbel', '2017-08-19 20:05:21', b'0', '', b'0'),
(325, 'licuadora oster classic+dni', 40, 4, '2017-07-19', '2017-08-19', '', 48, 0, 244, b'0', b'0', '2017-07-19 18:09:41', 3, 1, '', 51.2, 'Aumbbel', '2017-09-05 19:17:10', b'0', '', b'0'),
(326, 'bluray samsung + multitester', 70, 4, '2017-07-20', '2017-08-20', '', 84, 0, 245, b'0', b'1', '2017-07-20 18:27:51', 3, 1, '', 0, '', '', b'0', '', b'0'),
(327, 'moto scuter pleasure', 400, 4, '2017-07-20', '2017-08-20', '', 480, 0, 246, b'0', b'0', '2017-07-20 18:51:17', 3, 1, '', 440, 'Yuri Paola', '2017-08-03 18:59:33', b'0', '', b'0'),
(328, 'skil+bauker+dremel3000', 130, 4, '2017-07-21', '2017-08-21', '', 156, 0, 247, b'0', b'1', '2017-07-21 13:30:52', 3, 1, '', 0, '', '', b'0', '', b'0'),
(329, 'laptop hp', 120, 4, '2017-07-22', '2017-07-23', 'CON CARGADOR ', 132, 0, 248, b'0', b'1', '2017-07-22 12:48:51', 12, 1, '', 0, '', '', b'0', '', b'0'),
(330, 'celular', 200, 4, '2017-07-22', '2017-07-23', '', 220, 0, 54, b'0', b'0', '2017-07-22 13:51:53', 9, 2, '', 264, '', '2017-09-12 12:52:49', b'0', '', b'0'),
(331, 'celular huawei cun-l03', 80, 4, '2017-07-25', '2017-08-25', '', 96, 0, 59, b'0', b'0', '2017-07-25 10:55:41', 3, 1, '', 88, 'Yuri Paola', '2017-08-01 13:37:12', b'0', '', b'0'),
(332, 'equipo lg dos parlantes', 150, 4, '2017-07-25', '2017-08-25', '', 180, 0, 249, b'0', b'0', '2017-07-25 12:38:31', 3, 1, '', 198, 'Yuri Paola', '2017-09-14 11:28:53', b'0', '', b'0'),
(333, 'olla arrocera imaco + microondas lg  + bluray philips', 150, 4, '2017-07-28', '2017-08-28', '', 180, 0, 250, b'0', b'0', '2017-07-28 11:00:37', 3, 1, '', 165, 'Pilar Maria', '2017-08-05 14:25:38', b'0', '', b'0'),
(334, 'parlante sony', 200, 4, '2017-07-28', '2017-08-28', '', 240, 0, 251, b'0', b'0', '2017-07-28 11:28:13', 3, 1, '', 232, 'Yuri Paola', '2017-08-22 18:31:59', b'0', '', b'0'),
(335, 'celular v10- lg h901', 250, 4, '2017-07-28', '2017-08-28', '', 300, 0, 252, b'0', b'0', '2017-07-28 16:03:03', 3, 1, '', 275, 'Yuri Paola', '2017-07-31 19:30:55', b'0', '', b'0'),
(336, 'laptop advance i3', 250, 4, '2017-07-28', '2017-08-28', '', 300, 0, 227, b'0', b'0', '2017-07-28 18:09:42', 3, 1, '', 275, 'Yuri Paola', '2017-08-02 12:39:37', b'0', '', b'0'),
(337, 'celular moto g play', 50, 4, '2017-07-27', '2017-08-27', '', 60, 0, 253, b'0', b'0', '2017-07-29 11:03:31', 13, 1, '', 55, 'Yuri Paola', '2017-08-02 11:12:18', b'0', '', b'0'),
(338, 'tv lg 42 pulgadas smartv', 380, 4, '2017-07-27', '2017-08-27', '', 456, 0, 254, b'0', b'1', '2017-07-29 11:04:44', 13, 1, '', 0, '', '', b'0', '', b'0'),
(339, 'equipo de sonido', 180, 4, '2017-07-27', '2017-08-27', '', 216, 0, 255, b'0', b'0', '2017-07-29 11:09:32', 13, 1, '', 223.2, 'Yuri Paola', '2017-09-05 15:50:00', b'0', '', b'0'),
(340, 'laptop sony, reloj casio, iphone 4, smartwacht', 1000, 4, '2017-07-27', '2017-08-27', '', 1200, 0, 256, b'0', b'0', '2017-07-29 11:12:43', 13, 1, '', 1100, 'Yuri Paola', '2017-08-02 11:07:29', b'0', '', b'0'),
(341, 'laptop', 200, 4, '2017-07-26', '2017-08-26', '', 240, 0, 257, b'0', b'1', '2017-07-29 11:16:28', 13, 1, '', 0, '', '', b'0', '', b'0'),
(342, 'camara canon', 40, 4, '2017-08-28', '2017-08-28', 'Se canceló el interés S/. 8.00 de el día 28/08/2017<br>', 48, 0, 15, b'0', b'1', '2017-07-29 11:18:55', 13, 1, '28/08/2017', 0, '', '', b'0', '', b'0'),
(343, 'microondas oster 20litros', 80, 4, '2017-07-27', '2017-08-27', '', 96, 0, 16, b'0', b'1', '2017-07-29 11:26:20', 13, 1, '', 0, '', '', b'0', '', b'0'),
(344, 'equipo sony 2parlantes', 300, 4, '2017-07-25', '2017-08-25', '', 360, 0, 250, b'0', b'0', '2017-07-29 11:33:15', 13, 1, '', 330, 'Pilar Maria', '2017-08-05 14:25:52', b'0', '', b'0'),
(345, 'camioneta toyota pick up- hilux año 2008', 15000, 4, '2017-07-31', '2017-08-31', '', 18000, 0, 258, b'0', b'0', '2017-07-31 14:05:52', 3, 1, '', 18000, 'Yuri Paola', '2017-08-29 12:47:20', b'0', '', b'0'),
(346, 'camara sony cyber shot dsc w730 + camara vucal', 150, 4, '2017-09-14', '2017-09-01', 'Se canceló el interés S/. 42.00 de el día 14/09/2017<br>', 180, 0, 259, b'0', b'1', '2017-08-01 17:45:39', 3, 1, '14/09/2017', 0, '', '', b'0', '', b'0'),
(347, 'laptop toshiba satellite l745 i3', 150, 4, '2017-08-02', '2017-09-02', 'sin cargador', 180, 0, 251, b'0', b'0', '2017-08-02 12:21:30', 3, 1, '', 168, 'Yuri Paola', '2017-08-22 18:31:45', b'0', '', b'0'),
(348, 'laptop toshiba skullcandy i5', 150, 4, '2017-08-02', '2017-09-02', 'pantalla rajada', 180, 0, 260, b'0', b'0', '2017-08-02 17:02:07', 3, 1, '', 186, 'Aumbbel', '2017-09-13 18:19:00', b'0', '', b'0'),
(349, 'celular sony xperia z3 + celular sony xperia e4', 170, 4, '2017-08-02', '2017-09-02', '', 204, 0, 261, b'0', b'1', '2017-08-02 19:14:08', 3, 1, '', 0, '', '', b'0', '', b'0'),
(350, 'laptop lenovo g50-45 con cargador', 400, 4, '2017-08-03', '2017-09-03', '', 480, 0, 262, b'0', b'1', '2017-08-03 16:38:57', 3, 1, '', 0, '', '', b'0', '', b'0'),
(351, 'moto yamaha yzf-r15', 2000, 4, '2017-08-03', '2017-09-03', '', 2400, 0, 118, b'0', b'0', '2017-08-03 18:08:52', 3, 1, '', 2240, '', '2017-08-24 12:50:13', b'0', '', b'0'),
(352, 'equipo de sonido sony ss wgr88p', 250, 4, '2017-09-08', '2017-09-07', 'Se canceló el interés S/. 50.00 de el día 08/09/2017<br>', 300, 0, 224, b'0', b'1', '2017-08-07 17:40:34', 3, 1, '08/09/2017', 0, '', '', b'0', '', b'0'),
(353, 'macbook pro i5 2015 - c02pc ay7fvh3', 988, 4, '2017-09-14', '2017-09-07', 'Se adelantó S/. 212.00 de S/. 1200.00 el día 14/09/2017<br>Se canceló el interés S/. 288.00 de el día 14/09/2017<br>', 1440, 212, 263, b'0', b'0', '2017-08-07 17:53:56', 3, 1, '14/09/2017', 1086.8, 'Pilar Maria', '2017-09-16 14:21:58', b'0', '', b'0'),
(354, 'equipo sonido sony 2 parlantes', 300, 4, '2017-08-07', '2017-09-07', '', 360, 0, 250, b'0', b'0', '2017-08-07 18:31:49', 3, 1, '', 330, 'Yuri Paola', '2017-08-17 17:45:07', b'0', '', b'0'),
(355, 'caja china', 500, 4, '2017-08-08', '2017-09-08', '', 600, 0, 264, b'0', b'1', '2017-08-08 15:05:42', 3, 1, '', 0, '', '', b'0', '', b'0'),
(356, 'laptop advance i3', 250, 4, '2017-09-12', '2017-09-08', 'Se canceló el interés S/. 50.00 de el día 12/09/2017<br>', 300, 0, 227, b'0', b'1', '2017-08-08 15:18:49', 3, 1, '12/09/2017', 0, '', '', b'0', '', b'0'),
(357, 'carro chevrolet sail - asq293', 8000, 4, '2017-08-08', '2017-10-08', '', 10880, 0, 265, b'0', b'0', '2017-08-08 15:29:28', 3, 1, '', 9600, '', '2017-09-08 12:13:15', b'0', '', b'0'),
(358, 'proyector epson h719a', 250, 4, '2017-08-08', '2017-09-08', '', 300, 0, 266, b'0', b'1', '2017-08-08 17:45:03', 3, 1, '', 0, '', '', b'0', '', b'0'),
(359, 'laptop sony vaio amd + camara canon', 250, 4, '2017-08-09', '2017-09-09', '', 300, 0, 119, b'0', b'0', '2017-08-09 16:26:11', 3, 1, '', 310, 'Yuri Paola', '2017-09-15 12:50:50', b'0', '', b'0'),
(360, 'extractora oster, batidora imaco', 50, 4, '2017-09-15', '2017-09-10', 'Se canceló el interés S/. 12.00 de el día 15/09/2017<br>', 60, 0, 156, b'0', b'1', '2017-08-10 10:36:23', 3, 1, '15/09/2017', 0, '', '', b'0', '', b'0'),
(361, 'auto nissan versa (plomo)', 5000, 4, '2017-08-11', '2017-09-11', '', 6000, 0, 267, b'0', b'0', '2017-08-11 12:06:58', 3, 1, '', 5500, 'Yuri Paola', '2017-08-15 11:03:13', b'0', '', b'0'),
(362, 'moto scuter jettor smaash 125 color rojo', 400, 4, '2017-08-14', '2017-09-14', '', 480, 0, 198, b'0', b'1', '2017-08-14 15:55:20', 3, 1, '', 0, '', '', b'0', '', b'0'),
(363, 'pistola mas generador', 1000, 4, '2017-08-12', '2017-09-12', '', 1200, 0, 268, b'0', b'0', '2017-08-14 18:22:36', 13, 1, '', 1200, '', '2017-09-11 16:33:49', b'0', '', b'0'),
(364, 'computadora corei3', 600, 4, '2017-09-14', '2017-09-12', 'Se canceló el interés S/. 120.00 de el día 14/09/2017<br>cel 959992364', 720, 0, 115, b'0', b'1', '2017-08-14 18:24:19', 13, 1, '14/09/2017', 0, '', '', b'0', '', b'0'),
(365, 'equipo de sonido samsung + zapatilla nike', 200, 4, '2017-08-15', '2017-09-15', '', 240, 0, 250, b'0', b'0', '2017-08-15 10:13:33', 3, 1, '', 220, '', '2017-08-17 17:44:35', b'0', '', b'0'),
(366, 'parlante + camara panasonic', 80, 4, '2017-08-15', '2017-09-15', '', 96, 0, 269, b'0', b'1', '2017-08-15 10:52:12', 3, 1, '', 0, '', '', b'0', '', b'0'),
(367, 'celular eksx x4+stil + reloj', 60, 4, '2017-09-13', '2017-09-15', 'Se canceló el interés S/. 12.00 de el día 13/09/2017<br>', 72, 0, 270, b'0', b'1', '2017-08-15 11:59:05', 3, 1, '13/09/2017', 0, '', '', b'0', '', b'0'),
(368, 'carro chevrolet sail - asq293 (agrego sobre empeño)', 2000, 4, '2017-08-15', '2017-09-15', '', 2400, 0, 265, b'0', b'0', '2017-08-15 12:18:41', 3, 1, '', 2320, '', '2017-09-08 12:13:01', b'0', '', b'0'),
(369, 'auto toyota yaris rojo f8e-518', 5000, 4, '2017-08-15', '2017-09-15', '', 6000, 0, 271, b'0', b'1', '2017-08-15 16:11:33', 3, 1, '', 0, '', '', b'0', '', b'0'),
(370, 'laptop hp 14 ac103la', 250, 4, '2017-08-16', '2017-09-16', '', 300, 0, 272, b'0', b'1', '2017-08-16 10:13:16', 3, 1, '', 0, '', '', b'0', '', b'0'),
(371, 'motocard azul 18566d', 1000, 4, '2017-08-16', '2017-09-16', '', 1200, 0, 273, b'0', b'1', '2017-08-16 10:36:17', 3, 1, '', 0, '', '', b'0', '', b'0'),
(372, 'equipo panasonic  sa max 5000', 450, 4, '2017-08-16', '2017-09-16', '', 540, 0, 274, b'0', b'1', '2017-08-16 18:42:56', 3, 1, '', 0, '', '', b'0', '', b'0'),
(373, 'llanta+gata+triangulo+estuche (5 herramientas)', 100, 4, '2017-09-18', '2017-09-17', 'Se canceló el interés S/. 20.00 de el día 18/09/2017<br>', 120, 0, 69, b'0', b'1', '2017-08-17 10:20:23', 3, 1, '18/09/2017', 0, '', '', b'0', '', b'0'),
(374, 'blu ray lg bp250', 50, 4, '2017-08-17', '2017-08-31', '', 55, 0, 275, b'0', b'0', '2017-08-17 11:17:23', 3, 1, '', 56, 'Yuri Paola', '2017-09-01 10:13:56', b'0', '', b'0'),
(375, 'guitarra electrica freeman', 150, 4, '2017-08-17', '2017-09-17', '', 180, 0, 276, b'0', b'1', '2017-08-17 12:25:59', 3, 1, '', 0, '', '', b'0', '', b'0'),
(376, 'laptop hp 14 r002la', 250, 4, '2017-08-17', '2017-09-17', '', 300, 0, 277, b'0', b'0', '2017-08-17 15:50:03', 3, 1, '', 275, 'Yuri Paola', '2017-08-23 15:47:38', b'0', '', b'0'),
(377, 'camara samsung st72', 40, 4, '2017-08-17', '2017-09-17', '', 48, 0, 278, b'0', b'1', '2017-08-17 19:18:29', 3, 1, '', 0, '', '', b'0', '', b'0'),
(378, 'laptop lenovo g50-45 amd a8', 500, 4, '2017-08-18', '2017-09-18', '', 600, 0, 279, b'0', b'1', '2017-08-18 18:01:11', 3, 1, '', 0, '', '', b'0', '', b'0'),
(379, 'laptop toshiba', 300, 4, '2017-08-19', '2017-09-19', 'Con cargador ', 360, 0, 280, b'0', b'1', '2017-08-19 09:54:07', 12, 1, '', 0, '', '', b'0', '', b'0'),
(380, 'impresora canon', 30, 4, '2017-08-19', '2017-08-20', '', 33, 0, 281, b'0', b'1', '2017-08-19 11:52:03', 12, 1, '', 0, '', '', b'0', '', b'0'),
(381, 'laptop toshiba satellite l55', 200, 4, '2017-08-21', '2017-09-21', '', 240, 0, 282, b'0', b'1', '2017-08-21 16:35:37', 3, 1, '', 0, '', '', b'0', '', b'0'),
(382, 'revolver ranger cal 38', 500, 4, '2017-08-21', '2017-09-21', '', 600, 0, 283, b'0', b'1', '2017-08-21 16:39:58', 3, 1, '', 0, '', '', b'0', '', b'0'),
(383, 'celular iphone 6s', 500, 4, '2017-09-04', '2017-09-21', 'Se canceló el interés S/. 50.00 de el día 04/09/2017<br>', 600, 0, 284, b'0', b'1', '2017-08-21 16:53:39', 3, 1, '04/09/2017', 0, '', '', b'0', '', b'0'),
(384, 'moto pulsar negro 3700-8w', 700, 4, '2017-08-21', '2017-09-21', '', 840, 0, 285, b'0', b'0', '2017-08-21 17:35:54', 3, 1, '', 770, 'Beatriz', '2017-08-22 13:40:13', b'0', '', b'0'),
(385, 'lavadora samsung', 250, 4, '2017-08-21', '2017-09-21', '', 300, 0, 250, b'0', b'0', '2017-08-21 19:07:43', 3, 1, '', 280, 'Aumbbel', '2017-09-06 21:14:11', b'0', '', b'0'),
(386, 'laptop lenovo core i 7', 850, 4, '2017-08-21', '2017-09-21', '', 1020, 0, 286, b'0', b'0', '2017-08-21 19:14:23', 3, 1, '', 986, '', '2017-09-12 09:54:44', b'0', '', b'0'),
(387, 'laptop lenovo core i 7', 850, 4, '2017-08-21', '2017-09-21', '', 1020, 0, 287, b'0', b'0', '2017-08-21 19:14:27', 3, 1, '', 952, 'Aumbbel', '2017-09-06 19:06:18', b'0', '', b'0'),
(388, 'laptop i5 hp', 450, 4, '2017-08-17', '2017-09-17', '', 540, 0, 288, b'0', b'0', '2017-08-22 10:19:04', 3, 1, '', 495, 'Yuri Paola', '2017-08-24 12:02:40', b'0', '', b'0'),
(389, '23 piezas en rena ware(ollas)', 3000, 4, '2017-08-22', '2017-09-23', '', 3600, 0, 289, b'0', b'1', '2017-08-22 11:43:13', 3, 1, '', 0, '', '', b'0', '', b'0'),
(390, 'celular j5', 150, 4, '2017-08-23', '2017-09-23', '', 180, 0, 290, b'0', b'1', '2017-08-23 12:43:00', 3, 1, '', 0, '', '', b'0', '', b'0'),
(391, 'monitor+mini notebook+ 2 tajeta de video+disco duro 1tb+2 lectora interna+bateria para laptop', 750, 4, '2017-08-23', '2017-09-23', '', 900, 0, 291, b'0', b'1', '2017-08-23 18:54:11', 3, 1, '', 0, '', '', b'0', '', b'0'),
(392, 'laptop toshiba basico', 100, 4, '2017-08-24', '2017-09-24', '', 120, 0, 292, b'0', b'0', '2017-08-24 10:16:09', 3, 1, '', 110, 'Yuri Paola', '2017-08-28 10:16:10', b'0', '', b'0'),
(393, 'filmadora jvc gy hmz1u', 600, 4, '2017-09-04', '2017-09-24', 'Se canceló el interés S/. 60.00 de el día 04/09/2017<br>', 720, 0, 293, b'0', b'1', '2017-08-24 11:54:18', 3, 1, '04/09/2017', 0, '', '', b'0', '', b'0'),
(394, 'laptop i5 hp', 550, 4, '2017-08-17', '2017-09-17', '', 660, 0, 288, b'0', b'0', '2017-08-24 12:04:23', 3, 1, '', 605, 'Yuri Paola', '2017-08-28 11:38:10', b'0', '', b'0'),
(395, 'lavadora samsung wa15j5730ls', 400, 4, '2017-08-24', '2017-09-24', '', 480, 0, 250, b'0', b'0', '2017-08-24 14:10:18', 3, 1, '', 440, 'Aumbbel', '2017-09-06 21:14:31', b'0', '', b'0'),
(396, 'computador de escritorio completo', 350, 4, '2017-08-24', '2017-09-24', '', 420, 0, 294, b'0', b'1', '2017-08-24 16:34:48', 3, 1, '', 0, '', '', b'0', '', b'0'),
(397, 'chocolatera renaware, filtro renaware, 2 licuadoras, una cocina repsol de mesa.', 1000, 4, '2017-08-25', '2017-09-25', 'solo al 10%', 1200, 0, 240, b'0', b'1', '2017-08-25 09:35:04', 8, 1, '', 0, '', '', b'0', '', b'0'),
(398, 'slyn gym body massager', 1000, 4, '2017-08-25', '2017-09-25', '', 1200, 0, 295, b'0', b'1', '2017-08-25 13:14:57', 3, 1, '', 0, '', '', b'0', '', b'0'),
(399, 'laptop asus', 400, 4, '2017-08-25', '2017-09-25', '', 480, 0, 296, b'0', b'1', '2017-08-25 15:00:09', 3, 1, '', 0, '', '', b'0', '', b'0'),
(400, 'soldadora sol andina + motosierra husqvarna 365', 1000, 4, '2017-08-25', '2017-09-25', '', 1200, 0, 297, b'0', b'1', '2017-08-25 16:49:25', 3, 1, '', 0, '', '', b'0', '', b'0'),
(401, 'laptop toshiba + celular', 100, 4, '2017-08-25', '2017-09-25', '', 120, 0, 298, b'0', b'1', '2017-08-25 18:57:06', 3, 1, '', 0, '', '', b'0', '', b'0'),
(402, 'laptop acer aspire e14 i5', 300, 4, '2017-08-25', '2017-09-25', '', 360, 0, 299, b'0', b'0', '2017-08-25 19:00:25', 3, 1, '', 330, 'Yuri Paola', '2017-08-28 11:44:47', b'0', '', b'0'),
(403, 'laptop hp + camara', 300, 4, '2017-08-25', '2017-08-24', 'Se canceló el interés S/. 60.00 de el día 25/08/2017<br>', 360, 0, 300, b'0', b'1', '2017-08-25 19:09:52', 3, 1, '25/08/2017', 0, '', '', b'0', '', b'0'),
(404, 'laptop hp i3 (bloqueado)', 200, 4, '2017-08-25', '2017-09-25', '', 240, 0, 301, b'0', b'1', '2017-08-25 19:19:29', 3, 1, '', 0, '', '', b'0', '', b'0'),
(405, 'laptop hp 14 r011la i5', 500, 4, '2017-08-28', '2017-09-28', '', 600, 0, 302, b'0', b'1', '2017-08-28 09:46:35', 3, 1, '', 0, '', '', b'0', '', b'0'),
(406, 'camioneta hilux w4w-726', 18000, 4, '2017-08-28', '2017-09-28', '', 21600, 0, 303, b'0', b'1', '2017-08-28 10:01:22', 3, 1, '', 0, '', '', b'0', '', b'0'),
(407, 'saxo prof', 700, 4, '2017-08-28', '2017-09-28', '', 840, 0, 304, b'0', b'1', '2017-08-28 12:06:25', 13, 1, '', 0, '', '', b'0', '', b'0'),
(408, 'zapatilla mas microondas', 150, 4, '2017-08-28', '2017-09-28', 'ZAPATILLAS MAS MICROONDAS', 180, 0, 250, b'0', b'0', '2017-08-28 12:09:27', 13, 1, '', 165, 'Aumbbel', '2017-09-06 21:15:13', b'0', '', b'0'),
(409, 'celular j3', 100, 4, '2017-08-29', '2017-09-29', '', 120, 0, 305, b'0', b'0', '2017-08-29 10:51:28', 3, 1, '', 112, 'Yuri Paola', '2017-09-14 15:35:27', b'0', '', b'0'),
(410, 'laptop toshiba l755 sin cargador', 100, 4, '2017-09-05', '2017-09-29', 'Se adelantó S/. 300.00 de S/. 400.00 el día 05/09/2017<br>Se canceló el interés S/. 40.00 de el día 05/09/2017<br>', 480, 300, 306, b'0', b'1', '2017-08-29 10:58:57', 3, 1, '05/09/2017', 0, '', '', b'0', '', b'0'),
(411, 'laptop hp 14', 200, 4, '2017-08-29', '2017-09-29', '', 240, 0, 307, b'0', b'0', '2017-08-29 11:18:14', 3, 1, '', 220, '', '2017-09-12 09:48:56', b'0', '', b'0'),
(412, 'tablet samsung t210', 70, 4, '2017-08-29', '2017-09-29', '', 84, 0, 308, b'0', b'1', '2017-08-29 13:49:46', 3, 1, '', 0, '', '', b'0', '', b'0'),
(413, 'laptop lenovo i3', 300, 4, '2017-08-30', '2017-09-30', '', 360, 0, 309, b'0', b'1', '2017-08-30 10:04:15', 3, 1, '', 0, '', '', b'0', '', b'0'),
(414, 'hp pavilion g4-1071 la notebook pc', 80, 4, '2017-08-30', '2017-09-09', '', 88, 0, 310, b'0', b'0', '2017-08-30 18:51:21', 3, 1, '', 88, '', '2017-09-11 16:40:19', b'0', '', b'0'),
(415, 'objetos odontologicos', 300, 4, '2017-08-31', '2017-09-30', '', 360, 0, 311, b'0', b'0', '2017-08-31 10:48:37', 3, 1, '', 336, 'Yuri Paola', '2017-09-15 10:32:08', b'0', '', b'0'),
(416, 'celular demo', 100, 4, '2017-08-31', '2017-09-01', '', 110, 0, 54, b'0', b'0', '2017-08-31 16:51:37', 9, 2, '', 110, 'demo', '2017-08-31 16:51:51', b'0', '', b'0'),
(417, 'laptop hp con cargador', 900, 4, '2017-09-01', '2017-10-01', '', 1080, 0, 312, b'0', b'1', '2017-09-01 10:40:28', 3, 1, '', 0, '', '', b'0', '', b'0'),
(418, 'laptop lenovo g550', 150, 4, '2017-09-01', '2017-10-01', '', 180, 0, 313, b'0', b'1', '2017-09-01 12:18:25', 3, 1, '', 0, '', '', b'0', '', b'0'),
(419, 'celular lg v10', 300, 4, '2017-09-01', '2017-10-01', '', 360, 0, 252, b'0', b'1', '2017-09-01 16:01:19', 3, 1, '', 0, '', '', b'0', '', b'0'),
(420, 'bajo electroco+ llanta', 700, 4, '2017-09-01', '2017-09-02', '', 770, 0, 314, b'0', b'0', '2017-09-01 18:11:15', 3, 1, '', 770, '', '2017-09-08 17:34:49', b'0', '', b'0'),
(421, 'laptop toshhiba,pistola, generador electrico', 1500, 4, '2017-09-02', '2017-09-03', 'laptop sin cargador ', 1650, 0, 268, b'0', b'1', '2017-09-02 12:54:57', 12, 1, '', 0, '', '', b'0', '', b'0'),
(422, 'tv smart lg 42lb5800', 450, 4, '2017-09-04', '2017-09-05', '', 495, 0, 156, b'0', b'0', '2017-09-04 10:26:13', 3, 1, '', 495, 'Beatriz', '2017-09-15 19:04:58', b'0', '', b'0'),
(423, 'moto yamaha 2757-4b sin casco', 1000, 4, '2017-09-04', '2017-09-05', '', 1100, 0, 315, b'0', b'1', '2017-09-04 15:43:19', 3, 1, '', 0, '', '', b'0', '', b'0'),
(424, 'guitarra prs + pedal pod hd 500x', 1000, 4, '2017-09-04', '2017-09-05', '', 1100, 0, 316, b'0', b'1', '2017-09-04 17:43:38', 3, 1, '', 0, '', '', b'0', '', b'0'),
(425, 'carro great wall', 3000, 4, '2017-09-04', '2017-09-05', '', 3300, 0, 317, b'0', b'0', '2017-09-04 18:01:29', 13, 1, '', 3300, '', '2017-09-10 10:20:46', b'0', '', b'0'),
(426, 'motocarga kamax ka250w-e', 1500, 4, '2017-09-04', '2017-09-05', '', 1650, 0, 299, b'0', b'1', '2017-09-04 18:53:34', 3, 1, '', 0, '', '', b'0', '', b'0'),
(427, 'bluray philips wifi + bluray lg', 150, 4, '2017-09-05', '2017-09-06', '', 165, 0, 156, b'0', b'0', '2017-09-05 12:54:50', 3, 1, '', 165, 'Beatriz', '2017-09-15 19:53:25', b'0', '', b'0'),
(428, 'laptop hp i5 - 15 bs032la', 500, 4, '2017-09-05', '2017-09-06', '', 550, 0, 318, b'0', b'0', '2017-09-05 15:08:06', 3, 1, '', 550, '', '2017-09-09 12:22:06', b'0', '', b'0'),
(429, 'ipod 16gb 5ta generacion', 100, 4, '2017-09-05', '2017-09-06', '', 110, 0, 319, b'0', b'0', '2017-09-05 17:39:07', 13, 1, '', 110, 'Aumbbel', '2017-09-13 13:56:43', b'0', '', b'0'),
(430, 'ipod 16gb 5ta generacion', 100, 4, '2017-08-23', '2017-09-06', '', 110, 0, 319, b'0', b'1', '2017-09-05 17:40:14', 13, 1, '', 0, '', '', b'0', '', b'0'),
(442, 'celular k10 + celular huawei', 500, 4, '2017-09-05', '2017-09-06', '', 550, 0, 326, b'0', b'0', '2017-09-05 19:45:17', 3, 1, '', 550, '', '2017-09-08 12:12:40', b'0', '', b'0'),
(433, 'laptop hp corei5', 350, 4, '2017-08-17', '2017-09-06', '', 616, 0, 288, b'0', b'0', '2017-08-17 17:46:13', 13, 1, '', 406, 'Yuri Paola', '2017-09-13 13:33:16', b'0', '', b'0'),
(434, 'laptop hp negra', 900, 4, '2017-09-01', '2017-09-06', '', 990, 0, 312, b'0', b'1', '2017-09-05 17:48:54', 13, 1, '', 0, '', '', b'0', '', b'0'),
(435, 'laptop reloj adidas', 250, 4, '2017-08-31', '2017-09-06', '', 275, 0, 251, b'0', b'0', '2017-09-05 17:50:51', 13, 1, '', 275, '', '2017-09-11 19:26:41', b'0', '', b'0'),
(436, 'carro great wall 4x2', 3000, 4, '2017-09-03', '2017-09-06', '', 3300, 0, 317, b'0', b'1', '2017-09-05 17:52:03', 13, 1, '', 0, '', '', b'0', '', b'0'),
(437, 'laptop hp pavilion amd a8', 210, 4, '2017-09-18', '2017-09-06', 'Se adelantó S/. 190.00 de S/. 400.00 el día 18/09/2017<br>Se canceló el interés S/. 80.00 de el día 18/09/2017<br>', 448, 190, 321, b'0', b'1', '2017-08-19 17:57:16', 13, 1, '18/09/2017', 0, '', '', b'0', '', b'0'),
(438, 'celuyular j2', 240, 4, '2017-08-19', '2017-09-06', '', 268.8, 0, 322, b'0', b'1', '2017-08-19 18:01:17', 13, 1, '', 0, '', '', b'0', '', b'0'),
(439, 'calculadora programable', 100, 4, '2017-08-23', '2017-09-06', '', 110, 0, 323, b'0', b'0', '2017-09-05 18:16:52', 13, 1, '', 112, '', '2017-09-12 12:41:58', b'0', '', b'0'),
(440, 'laptop hp corei3', 350, 4, '2017-08-19', '2017-09-06', '', 392, 0, 324, b'0', b'1', '2017-09-05 18:20:35', 13, 1, '', 0, '', '', b'0', '', b'0'),
(441, 'camara canon negro', 500, 4, '2017-08-11', '2017-09-06', 'se revisara en la hoja ', 580, 0, 325, b'0', b'0', '2017-08-11 18:23:31', 13, 1, '', 600, 'Aumbbel', '2017-09-13 18:43:54', b'0', '', b'0'),
(443, 'tv samsung 32\" j4300', 350, 4, '2017-09-07', '2017-09-08', '', 385, 0, 327, b'0', b'0', '2017-09-07 09:39:27', 3, 1, '', 385, '', '2017-09-08 09:38:57', b'0', '', b'0'),
(444, 'celular p9 lite', 150, 4, '2017-09-07', '2017-09-08', '', 165, 0, 328, b'0', b'1', '2017-09-07 09:47:16', 3, 1, '', 0, '', '', b'0', '', b'0'),
(445, 'tv lg 42lb5610 + bluray philips', 450, 4, '2017-09-07', '2017-09-08', '', 495, 0, 250, b'0', b'0', '2017-09-07 09:56:01', 3, 1, '', 495, 'Yuri Paola', '2017-09-13 11:25:26', b'0', '', b'0'),
(446, 'laptop toshiba marron i5', 500, 4, '2017-09-06', '2017-09-08', '', 550, 0, 329, b'0', b'1', '2017-09-06 11:17:17', 3, 1, '', 0, '', '', b'0', '', b'0'),
(447, 'lavadora lg t1265tp', 300, 4, '2017-09-08', '2017-09-09', '', 330, 0, 332, b'0', b'1', '2017-09-08 13:43:24', 3, 1, '', 0, '', '', b'0', '', b'0'),
(448, 'celular j7', 200, 4, '2017-09-08', '2017-09-09', '', 220, 0, 250, b'0', b'0', '2017-09-08 16:20:56', 3, 1, '', 220, 'Yuri Paola', '2017-09-13 11:26:14', b'0', '', b'0'),
(449, 'celular huawei', 300, 4, '2017-09-08', '2017-09-09', 'con cargador', 330, 0, 333, b'0', b'1', '2017-09-08 17:39:37', 13, 1, '', 0, '', '', b'0', '', b'0'),
(452, 'celular huawei p9 lite + celular samsung s6 edge', 400, 4, '2017-09-08', '2017-09-09', '', 440, 0, 334, b'0', b'1', '2017-09-08 18:51:20', 3, 1, '', 0, '', '', b'0', '', b'0'),
(451, 'camara nikon + filmadora canon', 600, 0, '2017-09-07', '0000-00-00', '', 0, 0, 331, b'0', b'1', '2017-09-07 12:35:02', 3, 1, '', 0, '', '', b'0', '', b'1'),
(453, 'tv smart samsumg', 280, 4, '2017-09-09', '2017-09-10', '', 308, 0, 335, b'0', b'0', '2017-09-09 12:17:49', 12, 1, '', 308, 'Yuri Paola', '2017-09-13 15:22:02', b'0', '', b'0'),
(454, 'laptop hp i5-15 bs0321a', 650, 4, '2017-09-09', '2017-09-10', '', 715, 0, 318, b'0', b'1', '2017-09-09 12:23:01', 12, 1, '', 0, '', '', b'0', '', b'0'),
(455, 'auto daewo lanos s.e. d90-023', 1200, 4, '2017-09-09', '2017-09-10', '', 1320, 0, 336, b'0', b'0', '2017-09-09 13:01:16', 12, 1, '', 0, '', '2017-09-09 13:08:41', b'0', '', b'0'),
(456, 'carro daewoo lanos d9q-023', 1300, 4, '2017-09-09', '2017-09-10', '', 1430, 0, 336, b'0', b'1', '2017-09-09 13:09:55', 12, 1, '', 0, '', '', b'0', '', b'0'),
(457, 'ps4 sony uni mando 3 juegos', 500, 4, '2017-09-09', '2017-09-10', 'esta a nombre de dos personas También de chis salas.', 550, 0, 337, b'0', b'1', '2017-09-09 16:01:50', 16, 1, '', 0, '', '', b'0', '', b'0'),
(458, 'abcoaster abdominals + impresora epson', 1000, 4, '2017-09-09', '2017-09-10', 'El cliente posee otro credito vigente, se debe verificar que retire tODOS los creditos, con esa condicion se le otorga 1000 soles mas', 1100, 0, 268, b'0', b'1', '2017-09-09 16:56:21', 16, 1, '', 0, '', '', b'0', '', b'0'),
(459, 'celular p9 lite smart - nuevo', 400, 4, '2017-09-11', '2017-09-12', '', 440, 0, 333, b'0', b'1', '2017-09-11 09:37:03', 3, 1, '', 0, '', '', b'0', '', b'0'),
(460, 'tv samsung mu6100', 700, 4, '2017-09-11', '2017-09-12', '', 770, 0, 338, b'0', b'1', '2017-09-11 11:47:14', 3, 1, '', 0, '', '', b'0', '', b'0'),
(461, 'laptop tosbiba satellite l755', 400, 0, '2017-09-11', '0000-00-00', '', 0, 0, 150, b'0', b'0', '2017-09-11 14:11:43', 3, 1, '', 440, 'Yuri Paola', '2017-09-13 14:38:23', b'0', '', b'1'),
(462, 'tv lg 32lh30frcon control y cable', 250, 4, '2017-09-11', '2017-09-12', '', 275, 0, 339, b'0', b'1', '2017-09-11 14:23:10', 3, 1, '', 0, '', '', b'0', '', b'0'),
(463, '2 congas con funda-lpy y 1 parche remo', 350, 4, '2017-09-11', '2017-09-12', '', 385, 0, 85, b'0', b'1', '2017-09-11 14:41:56', 3, 1, '', 0, '', '', b'0', '', b'0'),
(464, 'equipo de sonido samsung', 180, 4, '2017-09-11', '2017-09-12', '', 198, 0, 12, b'0', b'1', '2017-09-11 15:38:18', 3, 1, '', 0, '', '', b'0', '', b'0'),
(465, 'auto mazda 6 w3u 559', 15000, 4, '2017-09-11', '2017-09-12', '', 16500, 0, 340, b'0', b'1', '2017-09-11 16:08:06', 3, 1, '', 0, '', '', b'0', '', b'0'),
(466, 'laptop compac', 80, 4, '2017-09-11', '2017-09-12', '', 88, 0, 341, b'0', b'0', '2017-09-11 20:04:42', 3, 1, '', 88, 'Yuri Paola', '2017-09-14 13:17:23', b'0', '', b'0'),
(467, 'camara fotografica lumix + audifono', 60, 0, '2017-07-24', '0000-00-00', '', 0, 0, 342, b'0', b'1', '2017-07-24 20:18:00', 3, 1, '', 0, '', '', b'0', '', b'1'),
(468, 'taladro bauker', 30, 4, '2017-06-21', '2017-09-12', '', 44.4, 0, 212, b'0', b'1', '2017-06-21 20:19:52', 3, 1, '', 0, '', '', b'0', '', b'0'),
(469, 'celular samsung s5', 100, 4, '2017-07-24', '2017-09-12', '', 132, 0, 343, b'0', b'1', '2017-07-24 20:33:21', 13, 1, '', 0, '', '', b'0', '', b'0'),
(470, 'tv 49\" lg + camara canon', 700, 4, '2017-09-12', '2017-09-13', '', 770, 0, 275, b'0', b'1', '2017-09-12 10:49:00', 3, 1, '', 0, '', '', b'0', '', b'0'),
(471, 'laptop amd', 300, 0, '2017-07-31', '0000-00-00', '', 0, 0, 344, b'0', b'1', '2017-07-31 11:37:46', 3, 1, '', 0, '', '', b'0', '', b'1'),
(472, 'micro cpu con cargador', 40, 0, '2017-09-12', '0000-00-00', '', 0, 0, 345, b'0', b'1', '2017-09-12 11:43:00', 3, 1, '', 0, '', '', b'0', '', b'1'),
(473, 'laptop i5 thinkpad', 350, 4, '2017-07-10', '2017-09-13', '', 490, 0, 346, b'0', b'1', '2017-07-10 11:45:20', 3, 1, '', 0, '', '', b'0', '', b'0'),
(474, 'celular microsoft lamia 9604', 150, 4, '2017-07-31', '2017-09-13', '', 192, 0, 15, b'0', b'1', '2017-07-31 11:58:17', 3, 1, '', 0, '', '', b'0', '', b'0'),
(475, 'laptop lenovo 250', 1100, 4, '2017-03-17', '2017-09-13', '500 soles de Interés ', 2244, 0, 90, b'0', b'1', '2017-03-17 12:00:32', 3, 1, '', 0, '', '', b'0', '', b'0'),
(476, 'laptop hp i3', 300, 0, '2017-06-10', '0000-00-00', '', 0, 0, 347, b'0', b'1', '2017-06-10 12:37:00', 3, 1, '', 0, '', '', b'0', '', b'1'),
(477, 'articulo prueba', 20, 4, '2017-09-12', '2017-09-13', '', 22, 0, 348, b'0', b'1', '2017-09-12 13:34:36', 9, 2, '', 0, '', '', b'0', '', b'0'),
(478, 'rotomartillo sin marca', 100, 4, '2017-09-12', '2017-09-13', '', 110, 0, 349, b'0', b'1', '2017-09-12 14:26:00', 13, 1, '', 0, '', '', b'0', '', b'0'),
(479, 'ps 4 cuh-1115a un mando', 400, 4, '2017-09-12', '2017-09-13', '', 440, 0, 350, b'0', b'1', '2017-09-12 18:07:59', 3, 1, '', 0, '', '', b'0', '', b'0'),
(480, 'prueba', 12, 4, '2017-09-12', '2017-09-13', '', 13.2, 0, 54, b'0', b'0', '2017-09-12 20:11:25', 9, 2, '', 13.2, 'demo', '2017-09-12 20:11:48', b'0', '', b'0'),
(481, 'tv lg 42lb65', 400, 4, '2017-08-07', '2017-09-14', '', 496, 0, 184, b'0', b'1', '2017-08-07 11:09:06', 3, 1, '', 0, '', '', b'0', '', b'0'),
(482, '2 parlantes micronics neon - spirit', 150, 4, '2017-09-13', '2017-09-14', '', 165, 0, 351, b'0', b'1', '2017-09-13 11:55:26', 3, 1, '', 0, '', '', b'0', '', b'0'),
(483, 'cpu + monitor + teclado + mause', 150, 0, '2017-04-10', '0000-00-00', '', 0, 0, 114, b'0', b'1', '2017-04-10 12:33:55', 3, 1, '', 0, '', '', b'0', '', b'1'),
(484, 'laptop toshiba satellite l755', 400, 0, '2017-05-11', '0000-00-00', '', 0, 0, 150, b'0', b'1', '2017-05-11 14:40:14', 3, 1, '', 0, '', '', b'0', '', b'1'),
(485, 'celular huawei cun-u29', 200, 4, '2017-09-11', '2017-09-14', '', 220, 0, 352, b'0', b'1', '2017-09-11 18:43:38', 3, 1, '', 0, '', '', b'0', '', b'0'),
(486, 'microondas lg+horno thomas+extractora thomas', 250, 4, '2017-09-13', '2017-09-14', '', 275, 0, 353, b'0', b'1', '2017-09-13 19:14:33', 3, 1, '', 0, '', '', b'0', '', b'0'),
(487, 'auto chevrolet asq-293', 12000, 4, '2017-09-14', '2017-09-15', '', 13200, 0, 265, b'0', b'1', '2017-09-14 11:27:52', 3, 1, '', 0, '', '', b'0', '', b'0'),
(488, '2 radios + impresora canon', 50, 4, '2017-09-14', '2017-09-15', '', 55, 0, 354, b'0', b'1', '2017-09-14 12:02:40', 3, 1, '', 0, '', '', b'0', '', b'0'),
(489, 'lavadora lg fuzzy ligic 10.5', 400, 4, '2017-09-14', '2017-09-15', '', 440, 0, 355, b'0', b'1', '2017-09-14 12:29:23', 3, 1, '', 0, '', '', b'0', '', b'0'),
(490, 'taladro 20v dewalt dcd776-026022', 80, 4, '2017-09-14', '2017-09-15', '', 88, 0, 181, b'0', b'1', '2017-09-14 12:38:27', 3, 1, '', 0, '', '', b'0', '', b'0'),
(491, 'celular s7dorazo', 500, 4, '2017-09-14', '2017-09-15', '', 550, 0, 356, b'0', b'1', '2017-09-14 17:59:25', 3, 1, '', 0, '', '', b'0', '', b'0'),
(492, 'aumento con su carro great wall 4x2', 2000, 4, '2017-09-15', '2017-09-16', '', 2200, 0, 317, b'0', b'1', '2017-09-15 10:27:37', 3, 1, '', 0, '', '', b'0', '', b'0'),
(493, 'laptop  hp probook 450 g4 + proyector epson x36', 2000, 4, '2017-09-15', '2017-09-16', '', 2200, 0, 357, b'0', b'1', '2017-09-15 12:17:30', 3, 1, '', 0, '', '', b'0', '', b'0'),
(494, 'celular lg x', 200, 4, '2017-09-15', '2017-09-16', '', 220, 0, 351, b'0', b'1', '2017-09-15 15:55:38', 13, 1, '', 0, '', '', b'0', '', b'0'),
(495, 'moto g 64', 400, 4, '2017-09-15', '2017-09-16', 'en caja nuevo', 440, 0, 358, b'0', b'1', '2017-09-15 16:52:32', 13, 1, '', 0, '', '', b'0', '', b'0'),
(496, 'camioneta toyota hilux  2015', 25000, 4, '2017-09-15', '2017-09-16', 'carro soat vencido', 27500, 0, 359, b'0', b'1', '2017-09-15 17:05:04', 13, 1, '', 0, '', '', b'0', '', b'0'),
(497, '20 carteras', 200, 4, '2017-09-15', '2017-09-16', '', 220, 0, 156, b'0', b'1', '2017-09-15 19:48:55', 13, 1, '', 0, '', '', b'0', '', b'0'),
(498, 'tv lg de 42\"', 400, 4, '2017-09-16', '2017-09-17', '', 440, 0, 250, b'0', b'1', '2017-09-16 11:53:43', 12, 1, '', 0, '', '', b'0', '', b'0'),
(499, 'tablet yoga lenovo', 250, 4, '2017-09-16', '2017-09-17', '', 275, 0, 360, b'0', b'1', '2017-09-16 12:33:40', 12, 1, '', 0, '', '', b'0', '', b'0'),
(500, 'laptop toshiba', 550, 4, '2017-09-16', '2017-09-17', '', 605, 0, 361, b'0', b'1', '2017-09-16 12:45:34', 12, 1, '', 0, '', '', b'0', '', b'0'),
(501, 'camara canon', 250, 4, '2017-09-16', '2017-09-17', '', 275, 0, 71, b'0', b'1', '2017-09-16 12:54:26', 12, 1, '', 0, '', '', b'0', '', b'0'),
(502, 'extractora renaware', 450, 4, '2017-09-16', '2017-09-17', '', 495, 0, 362, b'0', b'1', '2017-09-16 16:24:32', 12, 1, '', 0, '', '', b'0', '', b'0'),
(503, 'tv hyundai led tv 32\" y camara canon power shot sx 41015', 600, 4, '2017-09-16', '2017-09-17', '', 660, 0, 363, b'0', b'1', '2017-09-16 18:06:03', 13, 1, '', 0, '', '', b'0', '', b'0'),
(504, 'celular samsung j7', 250, 4, '2017-09-18', '2017-09-19', '', 275, 0, 250, b'0', b'1', '2017-09-18 10:12:35', 3, 1, '', 0, '', '', b'0', '', b'0'),
(505, 'una motocicleta marca barsha modelo lamger r17 placa 1028-0w', 400, 4, '2017-09-18', '2017-09-19', '', 440, 0, 113, b'0', b'1', '2017-09-18 11:17:18', 3, 1, '', 0, '', '', b'0', '', b'0'),
(506, 'lavadora daewoo+minicomponente mx js5500', 800, 4, '2017-09-18', '2017-09-19', '', 880, 0, 364, b'0', b'1', '2017-09-18 12:04:28', 3, 1, '', 0, '', '', b'0', '', b'0'),
(507, 'laptop hp g4 + dni', 120, 4, '2017-09-18', '2017-09-19', '', 132, 0, 365, b'0', b'1', '2017-09-18 12:21:35', 3, 1, '', 0, '', '', b'0', '', b'0'),
(508, 'celular j3', 150, 4, '2017-09-18', '2017-09-19', '', 165, 0, 305, b'0', b'1', '2017-09-18 12:26:50', 3, 1, '', 0, '', '', b'0', '', b'0'),
(509, 'moto ronco aggressor 200- 0930-0w', 1000, 4, '2017-09-18', '2017-09-19', '', 1100, 0, 366, b'0', b'1', '2017-09-18 00:52:04', 3, 1, '', 0, '', '', b'0', '', b'0'),
(510, 'laptop toshiba i5 3g', 350, 4, '2017-09-18', '2017-09-19', '', 385, 0, 367, b'0', b'1', '2017-09-18 02:45:47', 3, 1, '', 0, '', '', b'0', '', b'0'),
(511, 'bluray philips wifi + bluray lg', 200, 4, '2017-09-18', '2017-09-19', '', 220, 0, 156, b'0', b'1', '2017-09-18 03:15:55', 3, 1, '', 0, '', '', b'0', '', b'0'),
(512, 'camara canon eos rebel t7 i', 1000, 4, '2017-09-18', '2017-09-19', '', 1100, 0, 368, b'0', b'1', '2017-09-18 05:05:44', 3, 1, '', 0, '', '', b'0', '', b'0');
INSERT INTO `producto` (`idProducto`, `prodNombre`, `prodMontoEntregado`, `prodInteres`, `prodFechaInicial`, `prodFechaVencimiento`, `prodObservaciones`, `prodMontoPagar`, `prodAdelanto`, `idCliente`, `prodDioAdelanto`, `prodActivo`, `prodFechaRegistro`, `idUsuario`, `idSucursal`, `prodUltimaFechaInteres`, `prodCuantoFinaliza`, `prodQuienFinaliza`, `prodFechaFinaliza`, `prodAprobado`, `prodQuienAprueba`, `esCompra`) VALUES
(513, 'vajilla nueva', 26, 4, '2017-09-18', '2017-09-19', '', 28.6, 0, 54, b'0', b'1', '2017-09-18 23:49:57', 9, 2, '', 0, '', '', b'0', '', b'0'),
(514, 'laptop lenovo g460 con cargador', 150, 4, '2017-09-19', '2017-09-20', '', 165, 0, 369, b'0', b'1', '2017-09-19 13:24:58', 3, 1, '', 0, '', '', b'0', '', b'0'),
(515, 'laptop hp amd a8', 250, 4, '2017-09-19', '2017-09-20', '', 275, 0, 370, b'0', b'1', '2017-09-19 14:13:11', 3, 1, '', 0, '', '', b'0', '', b'0'),
(516, 'tv lg 49uj6510', 1000, 4, '2017-09-19', '2017-09-20', '', 1100, 0, 371, b'0', b'1', '2017-09-19 15:43:26', 3, 1, '', 0, '', '', b'0', '', b'0'),
(517, 'laptop i3 samsung (media pantalla borrasa) + calculadora hp 50g', 350, 4, '2017-09-19', '2017-09-20', '', 385, 0, 372, b'0', b'1', '2017-09-19 17:08:59', 3, 1, '', 0, '', '', b'0', '', b'0'),
(518, 'laptop core i3 intel', 400, 4, '2017-09-19', '2017-09-20', 'ojo:: Nuevo num Celular 966514548', 440, 0, 206, b'0', b'1', '2017-09-19 19:48:11', 8, 1, '', 0, '', '', b'0', '', b'0'),
(519, 'auto nissan sentra ack-188', 3500, 4, '2017-09-20', '2017-09-21', '', 3850, 0, 373, b'0', b'1', '2017-09-20 09:50:38', 3, 1, '', 0, '', '', b'0', '', b'0'),
(520, 'cpu amd athlon ii', 200, 4, '2017-09-20', '2017-09-21', '', 220, 0, 374, b'0', b'1', '2017-09-20 11:37:46', 3, 1, '', 0, '', '', b'0', '', b'0'),
(521, 'refrigerador samsung', 600, 4, '2017-09-20', '2017-09-21', '', 660, 0, 375, b'0', b'1', '2017-09-20 11:57:50', 3, 1, '', 0, '', '', b'0', '', b'0'),
(522, 'ps3 con un solo mando y un cable', 100, 4, '2017-09-20', '2017-09-21', '', 110, 0, 180, b'0', b'1', '2017-09-20 16:10:12', 3, 1, '', 0, '', '', b'0', '', b'0'),
(523, 'olla presión rena ware', 300, 4, '2017-09-20', '2017-09-21', '', 330, 0, 376, b'0', b'1', '2017-09-20 16:17:30', 3, 1, '', 0, '', '', b'0', '', b'0'),
(524, 'aspiradora stanley ipx4', 300, 4, '2017-09-20', '2017-09-21', '', 330, 0, 377, b'0', b'1', '2017-09-20 18:58:37', 3, 1, '', 0, '', '', b'0', '', b'0'),
(525, 'armamento girsan t636814y00603', 900, 4, '2017-09-21', '2017-09-22', '', 990, 0, 378, b'0', b'1', '2017-09-21 10:25:37', 3, 1, '', 0, '', '', b'0', '', b'0'),
(526, 'laptop advance 5444', 170, 4, '2017-09-21', '2017-09-22', '', 187, 0, 47, b'0', b'1', '2017-09-21 17:06:32', 3, 1, '', 0, '', '', b'0', '', b'0'),
(527, 'tablet olitec 808 + impresora pixma', 350, 4, '2017-09-21', '2017-09-22', '', 385, 0, 379, b'0', b'1', '2017-09-21 18:02:25', 3, 1, '', 0, '', '', b'0', '', b'0'),
(528, 'celular j7', 250, 4, '2017-09-21', '2017-09-22', '', 275, 0, 106, b'0', b'1', '2017-09-21 18:36:34', 3, 1, '', 0, '', '', b'0', '', b'0'),
(529, 'audifono mas dni', 20, 4, '2017-09-22', '2017-09-23', '', 22, 0, 380, b'0', b'1', '2017-09-22 09:14:46', 13, 1, '', 0, '', '', b'0', '', b'0'),
(530, 'maletines puma', 50, 4, '2017-09-22', '2017-09-23', '', 55, 0, 156, b'0', b'1', '2017-09-22 10:34:47', 3, 1, '', 0, '', '', b'0', '', b'0'),
(531, 'televisor samsung 5005 40\"', 400, 4, '2017-09-22', '2017-09-23', '', 440, 0, 381, b'0', b'1', '2017-09-22 14:27:27', 3, 1, '', 0, '', '', b'0', '', b'0'),
(532, 'bluray sin control lg bp450', 100, 4, '2017-09-22', '2017-09-23', '', 110, 0, 382, b'0', b'1', '2017-09-22 16:04:01', 3, 1, '', 0, '', '', b'0', '', b'0'),
(533, 'video camara sony hdr cx405', 300, 4, '2017-09-22', '2017-09-23', '', 330, 0, 383, b'0', b'1', '2017-09-22 16:31:27', 3, 1, '', 0, '', '', b'0', '', b'0'),
(534, 'canon powershot sx700 hs', 300, 0, '2017-09-22', '0000-00-00', '', 0, 0, 384, b'0', b'1', '2017-09-22 16:51:02', 3, 1, '', 0, '', '', b'0', '', b'1'),
(535, 'teclado viejo', 60, 4, '2017-09-22', '2017-09-23', '', 66, 0, 54, b'0', b'0', '2017-09-22 17:24:00', 9, 2, '22/09/2017', 0, '', '', b'0', '', b'0'),
(536, 'mousepad', 11, 4, '2017-09-22', '2017-09-23', '', 12.1, 0, 54, b'0', b'1', '2017-09-22 18:02:09', 1, 1, '22/09/2017', 0, '', '', b'0', '', b'0'),
(537, 'mousepad 2', 40, 4, '2017-09-22', '2017-09-23', '', 44, 0, 54, b'0', b'0', '2017-09-22 18:42:05', 1, 1, '22/09/2017', 0, '', '', b'0', '', b'0'),
(538, 'videocamara canon', 400, 4, '2017-09-22', '2017-09-23', '', 440, 0, 385, b'0', b'1', '2017-09-22 18:42:28', 13, 1, '', 0, '', '', b'0', '', b'0');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reportes_producto`
--

CREATE TABLE `reportes_producto` (
  `idReporte` int(11) NOT NULL,
  `idProducto` int(11) NOT NULL,
  `idDetalleReporte` int(11) NOT NULL,
  `repoValorMonetario` float NOT NULL,
  `repoFechaOcurrencia` datetime NOT NULL,
  `repoUsuario` varchar(200) NOT NULL,
  `repoUsuarioComentario` varchar(200) NOT NULL,
  `repoFechaConfirma` varchar(200) NOT NULL,
  `repoQueConfirma` int(11) NOT NULL,
  `repoQuienConfirma` varchar(200) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `reportes_producto`
--

INSERT INTO `reportes_producto` (`idReporte`, `idProducto`, `idDetalleReporte`, `repoValorMonetario`, `repoFechaOcurrencia`, `repoUsuario`, `repoUsuarioComentario`, `repoFechaConfirma`, `repoQueConfirma`, `repoQuienConfirma`) VALUES
(18, 227, 3, 78.4, '2017-06-26 17:35:04', '', '', '2017-06-26 20:04:55', 5, 'Aumbbel'),
(17, 211, 3, 1160, '2017-06-24 12:07:05', 'Pilar Maria', '', '2017-06-26 20:05:10', 5, 'Aumbbel'),
(16, 10, 3, 73.73, '2017-06-24 09:11:27', 'Pilar Maria', '', '2017-06-26 20:05:28', 5, 'Aumbbel'),
(15, 37, 3, 1120, '2017-06-23 19:38:48', 'manrique', '', '2017-06-23 19:39:04', 6, 'manrique'),
(14, 217, 3, 224, '2017-06-23 18:58:39', 'Yuri Paola', '', '2017-06-23 19:36:52', 6, 'manrique'),
(12, 20, 3, 360, '2017-06-23 09:56:14', 'Yuri Paola', '', '2017-06-23 19:36:41', 6, 'manrique'),
(13, 208, 1, 80, '2017-06-23 15:44:34', ' Yuri Paola', '', '2017-06-23 19:37:42', 7, 'manrique'),
(19, 262, 3, 550, '2017-06-26 18:21:50', '', '', '2017-06-26 20:08:26', 5, 'Aumbbel'),
(20, 69, 3, 172, '2017-06-26 20:22:24', 'Aumbbel', '', '2017-06-27 11:30:00', 5, 'Aumbbel'),
(21, 246, 3, 187, '2017-06-27 10:25:43', 'Yuri Paola', '', '2017-06-27 11:10:48', 5, 'Aumbbel'),
(22, 185, 3, 220, '2017-06-27 12:06:53', 'Yuri Paola', '', '2017-06-27 17:28:51', 5, 'Aumbbel'),
(23, 257, 3, 363, '2017-06-27 14:45:02', '', '', '2017-06-27 17:28:54', 5, 'Aumbbel'),
(24, 180, 3, 128, '2017-06-27 16:42:40', '', '', '2017-06-27 17:01:15', 5, 'Aumbbel'),
(25, 265, 1, 45, '2017-06-28 18:41:39', ' ', '', '2017-06-28 20:03:50', 7, 'Aumbbel'),
(26, 265, 3, 495, '2017-06-28 18:42:26', 'Yuri Paola', '', '2017-06-28 20:03:15', 5, 'Aumbbel'),
(27, 282, 3, 330, '2017-06-28 18:42:47', 'Yuri Paola', '', '2017-06-28 20:02:56', 5, 'Aumbbel'),
(28, 123, 3, 103.6, '2017-06-28 20:04:53', 'Yuri Paola', '', '2017-06-28 20:25:30', 6, 'Aumbbel'),
(29, 8, 3, 82.56, '2017-06-28 20:05:24', 'Yuri Paola', '', '2017-06-28 20:25:27', 6, 'Aumbbel'),
(30, 89, 3, 1394, '2017-06-28 20:05:55', 'Yuri Paola', '', '2017-06-28 20:26:25', 6, 'Aumbbel'),
(31, 96, 3, 1760, '2017-06-28 20:06:18', 'Yuri Paola', '', '2017-06-28 20:26:28', 6, 'Aumbbel'),
(32, 103, 3, 312, '2017-06-28 20:07:03', 'Yuri Paola', '', '2017-06-28 20:26:19', 6, 'Aumbbel'),
(33, 108, 3, 312, '2017-06-28 20:07:31', 'Yuri Paola', '', '2017-06-28 20:26:40', 6, 'Aumbbel'),
(34, 113, 3, 456, '2017-06-28 20:07:51', 'Yuri Paola', '', '2017-06-28 20:25:11', 6, 'Aumbbel'),
(35, 126, 3, 222, '2017-06-28 20:08:05', 'Yuri Paola', '', '2017-06-28 20:26:44', 6, 'Aumbbel'),
(36, 131, 3, 2220, '2017-06-28 20:08:55', 'Yuri Paola', '', '2017-06-28 20:24:19', 5, 'Aumbbel'),
(37, 137, 3, 432, '2017-06-28 20:09:58', 'Yuri Paola', '', '2017-06-28 20:25:04', 6, 'Aumbbel'),
(38, 136, 3, 288, '2017-06-28 20:10:19', 'Yuri Paola', '', '2017-06-28 20:24:09', 6, 'Aumbbel'),
(39, 149, 3, 420, '2017-06-28 20:10:41', 'Yuri Paola', '', '2017-06-28 20:24:56', 6, 'Aumbbel'),
(40, 135, 3, 216, '2017-06-28 20:10:59', 'Yuri Paola', '', '2017-06-28 20:26:53', 6, 'Aumbbel'),
(41, 143, 3, 216, '2017-06-28 20:11:32', 'Yuri Paola', '', '2017-06-28 20:24:50', 6, 'Aumbbel'),
(42, 158, 3, 68, '2017-06-28 20:11:48', 'Yuri Paola', '', '2017-06-28 20:23:28', 6, 'Aumbbel'),
(43, 155, 3, 272, '2017-06-28 20:12:42', 'Yuri Paola', '', '2017-06-28 20:24:45', 6, 'Aumbbel'),
(44, 101, 3, 560, '2017-06-28 20:13:50', 'Yuri Paola', '', '2017-06-28 20:26:59', 6, 'Aumbbel'),
(45, 138, 3, 216, '2017-06-28 20:14:49', 'Yuri Paola', '', '2017-06-28 20:27:08', 5, 'Aumbbel'),
(46, 157, 3, 326.4, '2017-06-28 20:15:48', 'Yuri Paola', '', '2017-06-28 20:27:28', 5, 'Aumbbel'),
(47, 156, 3, 408, '2017-06-28 20:16:15', 'Yuri Paola', '', '2017-06-28 20:27:48', 5, 'Aumbbel'),
(48, 181, 3, 448, '2017-06-28 20:17:14', 'Yuri Paola', '', '2017-06-28 20:24:36', 6, 'Aumbbel'),
(49, 173, 3, 512, '2017-06-28 20:18:20', 'Yuri Paola', '', '2017-06-28 20:27:43', 6, 'Aumbbel'),
(50, 195, 3, 186, '2017-06-28 20:32:09', 'Aumbbel', '', '2017-06-28 20:32:16', 5, 'Aumbbel'),
(51, 238, 1, 36, '2017-06-29 15:57:12', ' Yuri Paola', '', '2017-06-30 19:50:45', 7, 'Aumbbel'),
(52, 293, 1, 240, '2017-06-30 19:39:11', ' Yuri Paola', '', '2017-06-30 19:50:50', 7, 'Aumbbel'),
(53, 287, 3, 110, '2017-07-01 11:07:47', 'Pilar Maria', '', '2017-07-03 10:43:35', 5, 'Aumbbel'),
(54, 294, 3, 275, '2017-07-03 15:49:01', 'Yuri Paola', '', '2017-07-05 18:58:05', 5, 'Aumbbel'),
(55, 206, 3, 124, '2017-07-03 17:27:27', '', '', '2017-07-05 18:58:23', 5, 'Aumbbel'),
(58, 279, 3, 220, '2017-07-04 17:01:09', 'Yuri Paola', '', '2017-07-05 19:14:05', 5, 'Aumbbel'),
(59, 230, 3, 174, '2017-07-04 18:01:37', '', '', '2017-07-05 19:13:28', 5, 'Aumbbel'),
(60, 218, 3, 360, '2017-07-05 09:42:23', 'Yuri Paola', '', '2017-07-05 19:14:45', 5, 'Aumbbel'),
(61, 203, 1, 48, '2017-07-05 16:54:25', ' Yuri Paola', '', '2017-07-05 19:15:28', 7, 'Aumbbel'),
(62, 292, 3, 1430, '2017-07-05 19:16:07', 'Beatriz', '', '2017-07-05 19:16:53', 5, 'Aumbbel'),
(63, 223, 1, 80, '2017-07-05 19:52:13', ' Beatriz', '', '2017-07-10 19:51:59', 7, 'Aumbbel'),
(64, 197, 1, 84, '2017-07-06 12:32:08', ' Beatriz', '', '2017-07-10 19:52:01', 7, 'Aumbbel'),
(65, 220, 3, 240, '2017-07-06 13:23:33', '', '', '', 4, 'Todavía sin aprobación'),
(66, 122, 2, 550, '2017-07-06 17:47:31', ' ', '', '2017-07-12 19:00:29', 7, 'Carlos Alex'),
(67, 122, 2, 550, '2017-07-06 17:48:04', ' Beatriz', '', '', 4, 'Todavía sin aprobación'),
(68, 122, 2, 110, '2017-07-06 17:49:36', ' Beatriz', '', '', 4, 'Todavía sin aprobación'),
(69, 252, 3, 58, '2017-07-07 13:47:41', 'manrique Mendoza', '', '2017-07-07 18:28:19', 5, 'Aumbbel'),
(70, 239, 3, 46.4, '2017-07-07 13:48:54', 'manrique Mendoza', '', '2017-07-07 18:28:16', 5, 'Aumbbel'),
(71, 258, 3, 448, '2017-07-07 17:51:40', 'manrique Mendoza', '', '2017-07-07 18:28:44', 5, 'Aumbbel'),
(72, 127, 3, 87.04, '2017-07-08 18:02:46', 'Beatriz', '', '2017-07-10 19:47:07', 5, 'Aumbbel'),
(73, 253, 1, 96, '2017-07-10 12:14:56', ' Yuri Paola', '', '2017-07-10 19:44:09', 7, 'Aumbbel'),
(74, 261, 3, 174, '2017-07-10 15:28:41', '', '', '2017-07-10 19:46:42', 5, 'Aumbbel'),
(75, 130, 3, 44.8, '2017-07-10 16:15:42', 'Yuri Paola', '', '2017-07-10 19:43:43', 5, 'Aumbbel'),
(76, 169, 1, 96, '2017-07-10 19:18:53', ' ', '', '2017-07-10 19:46:15', 7, 'Aumbbel'),
(77, 225, 3, 148.8, '2017-07-11 10:17:04', 'Yuri Paola', '', '2017-07-11 19:26:57', 6, 'Aumbbel'),
(78, 58, 3, 1316, '2017-07-11 12:52:23', 'Aumbbel', '', '2017-07-11 12:52:33', 6, 'Aumbbel'),
(79, 205, 3, 512, '2017-07-11 19:28:08', 'Aumbbel', '', '2017-07-11 19:28:17', 6, 'Aumbbel'),
(80, 263, 3, 464, '2017-07-12 09:51:25', 'Yuri Paola', '', '2017-07-12 09:56:19', 5, 'Aumbbel'),
(81, 255, 3, 696, '2017-07-12 13:24:10', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(82, 288, 1, 60, '2017-07-12 13:24:30', ' Yuri Paola', '', '2017-07-31 23:20:19', 7, 'Aumbbel'),
(83, 316, 3, 165, '2017-07-12 17:05:12', 'demo', '', '', 4, 'Todavía sin aprobación'),
(84, 308, 3, 560, '2017-07-12 17:05:58', 'demo', '', '', 4, 'Todavía sin aprobación'),
(85, 317, 3, 132, '2017-07-12 18:45:57', 'demo', '', '', 4, 'Todavía sin aprobación'),
(86, 264, 3, 406, '2017-07-13 16:02:19', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(87, 280, 3, 672, '2017-07-14 10:39:25', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(88, 76, 3, 230.4, '2017-07-14 10:39:57', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(89, 272, 3, 464, '2017-07-14 13:48:46', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(90, 302, 3, 66, '2017-07-15 17:36:08', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(91, 208, 3, 580, '2017-07-17 09:03:55', 'Yuri Paola', '', '2017-08-07 19:48:36', 5, 'Aumbbel'),
(92, 129, 1, 40, '2017-07-17 09:58:42', ' Yuri Paola', '', '2017-07-31 23:20:00', 7, 'Aumbbel'),
(93, 238, 1, 36, '2017-07-17 12:32:55', ' Yuri Paola', '', '2017-07-31 23:19:57', 7, 'Aumbbel'),
(94, 248, 1, 10, '2017-07-17 15:42:23', ' Yuri Paola', '', '2017-07-31 23:19:55', 7, 'Aumbbel'),
(95, 321, 3, 248, '2017-07-17 20:10:18', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(96, 285, 3, 81.2, '2017-07-18 13:46:40', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(97, 199, 1, 300, '2017-07-18 17:24:00', ' ', '', '2017-07-31 23:19:52', 7, 'Aumbbel'),
(98, 184, 1, 60, '2017-07-18 18:41:24', ' Yuri Paola', '', '2017-07-31 23:19:49', 7, 'Aumbbel'),
(99, 290, 3, 235.2, '2017-07-20 12:13:02', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(100, 273, 1, 128, '2017-07-20 17:52:48', ' ', '', '2017-07-31 23:20:04', 7, 'Aumbbel'),
(101, 281, 1, 32, '2017-07-21 11:59:55', ' Yuri Paola', '', '2017-07-31 23:20:06', 7, 'Aumbbel'),
(102, 288, 3, 660, '2017-07-21 12:54:06', '', '', '2017-08-02 20:13:10', 5, 'Aumbbel'),
(103, 300, 3, 840, '2017-07-21 17:29:36', '', '', '', 4, 'Todavía sin aprobación'),
(104, 311, 1, 45, '2017-07-21 17:30:05', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(105, 311, 3, 450, '2017-07-21 17:30:34', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(106, 256, 2, 72, '2017-07-22 13:42:20', ' ', '', '', 4, 'Todavía sin aprobación'),
(107, 314, 3, 88, '2017-07-24 10:44:34', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(108, 276, 1, 80, '2017-07-24 15:53:51', ' Beatriz', '', '2017-07-31 23:20:10', 7, 'Aumbbel'),
(109, 286, 1, 1600, '2017-07-25 16:54:46', ' ', '', '2017-07-31 23:20:12', 7, 'Aumbbel'),
(110, 296, 3, 406, '2017-07-27 12:48:47', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(111, 301, 3, 232, '2017-07-27 17:16:53', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(112, 253, 3, 672, '2017-07-31 09:47:03', 'Yuri Paola', '', '2017-07-31 23:50:20', 5, 'Aumbbel'),
(113, 291, 3, 300, '2017-07-31 15:08:43', 'Yuri Paola', '', '2017-07-31 23:50:18', 5, 'Aumbbel'),
(114, 335, 3, 275, '2017-07-31 19:30:55', 'Yuri Paola', '', '2017-07-31 23:50:07', 5, 'Aumbbel'),
(115, 283, 3, 120, '2017-07-31 21:10:58', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(116, 286, 3, 11000, '2017-07-31 23:53:21', 'Aumbbel', '', '2017-07-31 23:53:46', 5, 'Aumbbel'),
(117, 9, 3, 832, '2017-07-31 23:58:02', 'Aumbbel', '', '2017-08-01 00:00:31', 6, 'Aumbbel'),
(118, 100, 3, 1760, '2017-07-31 23:58:24', 'Aumbbel', '', '2017-08-01 00:00:28', 6, 'Aumbbel'),
(119, 187, 3, 864, '2017-07-31 23:58:52', 'Aumbbel', '', '2017-08-01 00:00:23', 6, 'Aumbbel'),
(120, 15, 3, 44.35, '2017-08-01 00:48:17', 'Aumbbel', '', '2017-08-02 20:11:49', 6, 'Aumbbel'),
(121, 145, 3, 656, '2017-08-01 00:48:57', 'Aumbbel', '', '2017-08-02 20:11:54', 6, 'Aumbbel'),
(122, 186, 3, 86.4, '2017-08-01 00:49:08', 'Aumbbel', '', '2017-08-02 20:11:58', 6, 'Aumbbel'),
(123, 196, 3, 100.8, '2017-08-01 00:49:24', 'Aumbbel', '', '2017-08-02 20:12:01', 6, 'Aumbbel'),
(124, 224, 3, 272, '2017-08-01 00:50:16', 'Aumbbel', '', '2017-08-02 20:12:05', 6, 'Aumbbel'),
(125, 259, 3, 384, '2017-08-01 01:26:00', 'Aumbbel', '', '2017-08-02 20:12:09', 6, 'Aumbbel'),
(126, 234, 3, 594, '2017-08-01 12:05:57', 'Yuri Paola', '', '2017-08-02 19:35:08', 5, 'Aumbbel'),
(127, 298, 3, 792, '2017-08-01 12:06:29', 'Yuri Paola', '', '2017-08-02 19:33:17', 5, 'Aumbbel'),
(128, 198, 3, 8640, '2017-08-01 12:07:02', 'Yuri Paola', '', '2017-08-02 19:33:13', 5, 'Aumbbel'),
(129, 233, 3, 11200, '2017-08-01 12:07:19', 'Yuri Paola', '', '2017-08-02 19:33:07', 5, 'Aumbbel'),
(130, 278, 3, 620, '2017-08-01 12:07:58', 'Yuri Paola', '', '2017-08-02 19:33:04', 5, 'Aumbbel'),
(131, 251, 3, 5120, '2017-08-01 12:08:16', 'Yuri Paola', '', '2017-08-02 19:33:00', 5, 'Aumbbel'),
(132, 331, 3, 88, '2017-08-01 13:37:12', 'Yuri Paola', '', '2017-08-02 20:12:25', 5, 'Aumbbel'),
(133, 340, 3, 1100, '2017-08-02 11:07:29', 'Yuri Paola', '', '2017-08-02 20:10:36', 5, 'Aumbbel'),
(134, 337, 3, 55, '2017-08-02 11:12:18', 'Yuri Paola', '', '2017-08-02 20:10:40', 5, 'Aumbbel'),
(135, 336, 3, 275, '2017-08-02 12:39:37', 'Yuri Paola', '', '2017-08-02 20:10:46', 5, 'Aumbbel'),
(136, 318, 3, 448, '2017-08-02 15:46:14', '', '', '2017-08-02 20:10:51', 5, 'Aumbbel'),
(137, 129, 3, 224, '2017-08-02 16:36:08', 'Yuri Paola', '', '2017-08-02 20:10:56', 5, 'Aumbbel'),
(138, 327, 3, 440, '2017-08-03 18:59:33', 'Yuri Paola', '', '2017-08-30 13:16:04', 5, 'Aumbbel'),
(139, 305, 1, 140, '2017-08-04 19:04:54', ' Carlos Alex', '', '2017-08-07 19:46:08', 7, 'Aumbbel'),
(140, 243, 3, 528, '2017-08-05 11:56:58', 'Yuri Paola', '', '2017-08-07 19:39:08', 5, 'Aumbbel'),
(141, 163, 3, 312, '2017-08-05 13:48:52', 'Aumbbel', '', '2017-08-07 19:45:18', 6, 'Aumbbel'),
(142, 174, 3, 608, '2017-08-05 13:50:07', 'Aumbbel', '', '2017-08-07 19:45:13', 6, 'Aumbbel'),
(143, 179, 3, 380, '2017-08-05 13:50:26', 'Aumbbel', '', '2017-08-07 19:45:10', 6, 'Aumbbel'),
(144, 188, 3, 296, '2017-08-05 13:50:45', 'Aumbbel', '', '2017-08-07 19:45:07', 6, 'Aumbbel'),
(145, 209, 3, 72, '2017-08-05 13:51:41', 'Aumbbel', '', '2017-08-07 19:45:05', 6, 'Aumbbel'),
(146, 213, 3, 140, '2017-08-05 13:52:15', 'Aumbbel', '', '2017-08-07 19:39:20', 5, 'Aumbbel'),
(147, 214, 3, 280, '2017-08-05 13:52:52', 'Aumbbel', '', '2017-08-07 19:45:02', 6, 'Aumbbel'),
(148, 222, 3, 476, '2017-08-05 13:53:52', 'Aumbbel', '', '2017-08-05 13:58:50', 6, 'Aumbbel'),
(149, 231, 3, 408, '2017-08-05 13:54:21', 'Aumbbel', '', '2017-08-07 19:44:59', 6, 'Aumbbel'),
(150, 236, 3, 408, '2017-08-05 13:55:07', 'Aumbbel', '', '2017-08-07 19:39:52', 6, 'Aumbbel'),
(151, 333, 3, 165, '2017-08-05 14:25:38', 'Pilar Maria', '', '2017-08-07 19:40:55', 5, 'Aumbbel'),
(152, 344, 3, 330, '2017-08-05 14:25:52', 'Pilar Maria', '', '2017-08-07 19:41:28', 5, 'Aumbbel'),
(153, 223, 1, 80, '2017-08-07 11:35:39', ' ', '', '2017-08-07 20:03:09', 7, 'Aumbbel'),
(154, 273, 3, 896, '2017-08-08 11:17:06', 'Yuri Paola', '', '2017-08-30 12:20:32', 5, 'Aumbbel'),
(155, 122, 3, -799.2, '2017-08-09 13:08:01', 'Yuri Paola', '', '2017-08-31 09:53:22', 5, 'Aumbbel'),
(156, 303, 3, 1664, '2017-08-14 15:17:34', '', '', '2017-08-31 09:55:46', 5, 'Aumbbel'),
(157, 361, 3, 5500, '2017-08-15 11:03:13', 'Yuri Paola', '', '2017-08-31 14:05:12', 5, 'Aumbbel'),
(158, 197, 3, 372, '2017-08-15 11:28:47', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(159, 315, 3, 600, '2017-08-16 10:02:48', 'Yuri Paola', '', '2017-09-06 20:13:21', 5, 'Aumbbel'),
(160, 199, 1, 300, '2017-08-16 17:09:51', ' Yuri Paola', '', '2017-09-06 19:47:43', 7, 'Aumbbel'),
(161, 238, 1, 60, '2017-08-17 17:13:56', ' ', '', '2017-09-06 19:47:40', 7, 'Aumbbel'),
(162, 365, 3, 220, '2017-08-17 17:44:35', '', '', '', 4, 'Todavía sin aprobación'),
(163, 354, 3, 330, '2017-08-17 17:45:07', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(164, 323, 3, 360, '2017-08-19 20:04:32', 'Aumbbel', '', '2017-09-06 19:47:15', 5, 'Aumbbel'),
(165, 324, 3, 240, '2017-08-19 20:05:21', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(166, 320, 3, 620, '2017-08-21 10:36:37', 'Yuri Paola', '', '2017-09-06 19:07:56', 5, 'Aumbbel'),
(167, 384, 3, 770, '2017-08-22 13:40:13', 'Beatriz', '', '2017-09-06 19:19:07', 5, 'Aumbbel'),
(168, 281, 1, 40, '2017-08-22 18:16:54', ' Yuri Paola', '', '2017-09-06 19:23:50', 7, 'Aumbbel'),
(169, 347, 3, 168, '2017-08-22 18:31:45', 'Yuri Paola', '', '2017-09-06 19:21:01', 5, 'Aumbbel'),
(170, 334, 3, 232, '2017-08-22 18:31:59', 'Yuri Paola', '', '2017-09-06 19:27:02', 5, 'Aumbbel'),
(171, 376, 3, 275, '2017-08-23 15:47:38', 'Yuri Paola', '', '2017-09-06 19:34:26', 5, 'Aumbbel'),
(172, 388, 3, 495, '2017-08-24 12:02:40', 'Yuri Paola', '', '2017-09-06 19:55:43', 5, 'Aumbbel'),
(173, 351, 3, 2240, '2017-08-24 12:50:13', '', '', '2017-09-06 19:46:43', 5, 'Aumbbel'),
(174, 313, 3, 1280, '2017-08-25 09:29:11', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(175, 310, 3, 358.4, '2017-08-25 17:31:45', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(176, 403, 1, 60, '2017-08-25 19:10:10', ' Yuri Paola', '', '2017-09-06 20:07:11', 7, 'Aumbbel'),
(177, 392, 3, 110, '2017-08-28 10:16:10', 'Yuri Paola', '', '2017-09-06 20:28:19', 5, 'Aumbbel'),
(178, 276, 1, 80, '2017-08-28 11:20:37', ' ', '', '2017-09-06 20:28:28', 7, 'Aumbbel'),
(179, 394, 3, 605, '2017-08-28 11:38:10', 'Yuri Paola', '', '2017-09-06 20:28:43', 5, 'Aumbbel'),
(180, 402, 3, 330, '2017-08-28 11:44:47', 'Yuri Paola', '', '2017-09-06 20:29:43', 5, 'Aumbbel'),
(181, 342, 1, 8, '2017-08-28 13:23:12', ' Yuri Paola', '', '2017-09-08 19:44:06', 7, ''),
(182, 345, 3, 18000, '2017-08-29 12:47:20', 'Yuri Paola', '', '2017-08-30 13:16:20', 5, 'Aumbbel'),
(183, 184, 3, 372, '2017-08-29 18:59:11', 'Yuri Paola', '', '2017-09-06 20:44:20', 5, 'Aumbbel'),
(184, 240, 3, 1184, '2017-08-30 13:11:03', 'Aumbbel', '', '2017-08-30 13:12:22', 6, 'Aumbbel'),
(185, 266, 3, 42, '2017-08-30 13:30:08', 'Aumbbel', '', '2017-09-06 20:49:42', 5, 'Aumbbel'),
(186, 416, 3, 110, '2017-08-31 16:51:51', 'demo', '', '', 4, 'Todavía sin aprobación'),
(187, 374, 3, 56, '2017-09-01 10:13:56', 'Yuri Paola', '', '2017-09-08 19:23:55', 5, ''),
(188, 393, 1, 60, '2017-09-04 13:08:54', ' Yuri Paola', '', '2017-09-08 19:44:38', 7, ''),
(189, 383, 1, 50, '2017-09-04 16:38:36', ' Yuri Paola', '', '2017-09-08 19:44:45', 7, ''),
(190, 410, 1, 40, '2017-09-05 14:16:10', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(191, 410, 2, 300, '2017-09-05 14:16:33', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(192, 339, 3, 223.2, '2017-09-05 15:50:00', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(193, 307, 3, 312.8, '2017-09-05 17:19:05', 'Aumbbel', '', '2017-09-05 19:17:28', 5, 'Aumbbel'),
(194, 325, 3, 51.2, '2017-09-05 19:17:10', 'Aumbbel', '', '2017-09-05 19:17:20', 5, 'Aumbbel'),
(195, 387, 3, 952, '2017-09-06 19:06:18', 'Aumbbel', '', '2017-09-06 19:06:29', 5, 'Aumbbel'),
(196, 385, 3, 280, '2017-09-06 21:14:11', 'Aumbbel', '', '2017-09-06 21:15:29', 5, 'Aumbbel'),
(197, 395, 3, 440, '2017-09-06 21:14:31', 'Aumbbel', '', '2017-09-06 21:15:31', 5, 'Aumbbel'),
(198, 408, 3, 165, '2017-09-06 21:15:13', 'Aumbbel', '', '2017-09-06 21:15:34', 5, 'Aumbbel'),
(199, 443, 3, 385, '2017-09-08 09:38:57', '', '', '', 4, 'Todavía sin aprobación'),
(200, 442, 3, 550, '2017-09-08 12:12:40', '', '', '', 4, 'Todavía sin aprobación'),
(201, 368, 3, 2320, '2017-09-08 12:13:01', '', '', '', 4, 'Todavía sin aprobación'),
(202, 357, 3, 9600, '2017-09-08 12:13:15', '', '', '', 4, 'Todavía sin aprobación'),
(203, 420, 3, 770, '2017-09-08 17:34:49', '', '', '', 4, 'Todavía sin aprobación'),
(204, 352, 1, 50, '2017-09-08 17:42:58', ' Beatriz', '', '', 4, 'Todavía sin aprobación'),
(205, 428, 3, 550, '2017-09-09 12:22:06', '', '', '', 4, 'Todavía sin aprobación'),
(206, 455, 3, 0, '2017-09-09 13:08:41', '', '', '2017-09-10 10:31:06', 5, ''),
(207, 425, 3, 3300, '2017-09-10 10:20:46', '', '', '2017-09-10 10:21:01', 5, ''),
(208, 363, 3, 1200, '2017-09-11 16:33:49', '', '', '2017-09-11 16:34:35', 5, ''),
(209, 414, 3, 88, '2017-09-11 16:40:19', '', '', '', 4, 'Todavía sin aprobación'),
(210, 435, 3, 275, '2017-09-11 19:26:41', '', '', '2017-09-13 14:24:57', 5, ''),
(211, 411, 3, 220, '2017-09-12 09:48:56', '', '', '2017-09-12 18:35:12', 5, ''),
(212, 386, 3, 986, '2017-09-12 09:54:44', '', '', '2017-09-12 18:35:15', 5, ''),
(213, 439, 3, 112, '2017-09-12 12:41:58', 'Yuri Paola', '', '2017-09-12 18:35:27', 5, ''),
(214, 330, 3, 264, '2017-09-12 12:52:49', '', '', '', 4, 'Todavía sin aprobación'),
(215, 223, 3, 496, '2017-09-12 13:13:36', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(216, 356, 1, 50, '2017-09-12 15:11:18', ' Yuri Paola', '', '2017-09-13 14:42:21', 7, ''),
(217, 480, 3, 13.2, '2017-09-12 20:11:48', 'demo', '', '', 4, 'Todavía sin aprobación'),
(218, 367, 1, 12, '2017-09-13 10:41:42', ' Beatriz', '', '2017-09-13 14:42:18', 7, ''),
(219, 445, 3, 495, '2017-09-13 11:25:26', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(220, 448, 3, 220, '2017-09-13 11:26:14', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(221, 433, 3, 406, '2017-09-13 13:33:16', 'Yuri Paola', '', '2017-09-13 13:33:28', 5, ''),
(222, 429, 3, 110, '2017-09-13 13:56:43', 'Aumbbel', '', '2017-09-13 13:56:51', 5, ''),
(223, 461, 3, 440, '2017-09-13 14:38:23', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(224, 453, 3, 308, '2017-09-13 15:22:02', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(225, 348, 3, 186, '2017-09-13 18:19:00', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(226, 441, 3, 600, '2017-09-13 18:43:54', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(227, 364, 1, 120, '2017-09-14 10:51:46', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(228, 332, 3, 198, '2017-09-14 11:28:53', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(229, 238, 1, 48, '2017-09-14 11:56:01', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(230, 346, 1, 42, '2017-09-14 12:20:23', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(231, 466, 3, 88, '2017-09-14 13:17:23', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(232, 409, 3, 112, '2017-09-14 15:35:27', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(233, 353, 1, 288, '2017-09-14 16:03:40', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(234, 353, 2, 212, '2017-09-14 16:04:43', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(235, 319, 1, 25.2, '2017-09-14 16:44:33', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(236, 322, 1, 36, '2017-09-14 16:44:54', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(237, 306, 3, 288, '2017-09-14 21:40:23', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(238, 415, 3, 336, '2017-09-15 10:32:08', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(239, 359, 3, 310, '2017-09-15 12:50:50', 'Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(240, 422, 3, 495, '2017-09-15 19:04:58', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(241, 427, 3, 165, '2017-09-15 19:53:25', 'Beatriz', '', '', 4, 'Todavía sin aprobación'),
(242, 360, 1, 12, '2017-09-15 19:53:53', ' Beatriz', '', '', 4, 'Todavía sin aprobación'),
(243, 353, 3, 1086.8, '2017-09-16 14:21:58', 'Pilar Maria', '', '', 4, 'Todavía sin aprobación'),
(244, 373, 1, 20, '2017-09-18 11:40:27', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(245, 437, 1, 80, '2017-09-18 17:39:35', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(246, 437, 2, 190, '2017-09-18 17:40:00', ' Yuri Paola', '', '', 4, 'Todavía sin aprobación'),
(247, 55, 8, 19, '2017-09-19 18:03:19', '9', '', '', 4, 'Todavía sin aprobación'),
(248, 140, 8, 90, '2017-09-19 19:15:52', '0', '', '', 4, 'Todavía sin aprobación'),
(249, 56, 8, 160, '2017-09-19 19:18:56', '0', '', '', 4, 'Todavía sin aprobación'),
(250, 64, 8, 140, '2017-09-19 19:24:35', '0', '', '', 4, 'Todavía sin aprobación'),
(251, 201, 8, 150, '2017-09-19 20:04:25', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(252, 204, 8, 200, '2017-09-19 20:06:15', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(253, 260, 8, 400, '2017-09-19 20:06:52', 'Aumbbel', '', '', 4, 'Todavía sin aprobación'),
(255, 316, 8, 150, '2017-09-20 17:39:58', 'demo', '', '', 4, 'Todavía sin aprobación'),
(256, 535, 9, 66.16, '2017-09-22 17:41:41', 'demo', '', '', 4, 'Todavía sin aprobación'),
(257, 535, 9, 66.16, '2017-09-22 17:43:54', 'demo', '', '', 4, 'Todavía sin aprobación'),
(258, 537, 8, 43.8, '2017-09-22 18:42:18', 'Carlos Alex', '', '', 4, 'Todavía sin aprobación');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursal`
--

CREATE TABLE `sucursal` (
  `idSucursal` int(11) NOT NULL,
  `sucNombre` varchar(50) NOT NULL,
  `sucLugar` varchar(200) NOT NULL,
  `sucActivo` bit(1) NOT NULL DEFAULT b'1' COMMENT '1 para activo'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `sucursal`
--

INSERT INTO `sucursal` (`idSucursal`, `sucNombre`, `sucLugar`, `sucActivo`) VALUES
(1, 'Las Retamas', 'Las Retamas 555 - La Rivera', b'1'),
(2, 'Av. Real 321', 'Av. Real 321', b'1'),
(3, 'Todas las oficinas', 'Todas las oficinas', b'1'),
(7, 'Agencia El Tambo', 'El Tambo', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tempo`
--

CREATE TABLE `tempo` (
  `idtempo` int(11) NOT NULL,
  `fecha` datetime NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `tempo`
--

INSERT INTO `tempo` (`idtempo`, `fecha`) VALUES
(1, '2017-09-07 11:37:18'),
(2, '0000-00-00 00:00:00'),
(3, '0000-00-00 00:00:00'),
(4, '0000-00-00 00:00:00'),
(5, '2017-09-07 11:41:50'),
(6, '2017-09-12 20:08:43');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipoProceso`
--

CREATE TABLE `tipoProceso` (
  `idTipoProceso` int(11) NOT NULL,
  `tipoDescripcion` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `tipoProceso`
--

INSERT INTO `tipoProceso` (`idTipoProceso`, `tipoDescripcion`) VALUES
(1, 'Entrada stock'),
(2, 'Venta'),
(3, 'Crédito nuevo'),
(4, 'Pérdida'),
(5, 'Egreso'),
(6, 'Ingreso'),
(7, 'Amortización'),
(8, 'Sin acción'),
(9, 'Adelanto interés'),
(10, 'Cancela interés'),
(11, 'Artículo retirado'),
(12, 'Artículo vigente'),
(13, 'Capital cancelado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idUsuario` int(11) NOT NULL,
  `usuNombres` varchar(100) NOT NULL,
  `usuApellido` varchar(100) NOT NULL,
  `usuNick` varchar(50) NOT NULL,
  `usuPass` varchar(100) NOT NULL,
  `usuPoder` int(11) NOT NULL,
  `idSucursal` int(11) NOT NULL,
  `usuActivo` bit(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idUsuario`, `usuNombres`, `usuApellido`, `usuNick`, `usuPass`, `usuPoder`, `idSucursal`, `usuActivo`) VALUES
(1, 'Carlos Alex', 'Pariona Valencia', 'cpariona', 'b84d8185d9fc5d64de366cc8a06d8ef1', 1, 3, b'1'),
(2, 'Yuri Paola', 'Huaycuch Valenzuela', 'phuaycuch', '69447f927b74151c1aeb626f31202e0a', 2, 1, b'1'),
(3, 'Yuri Paola', 'Huaycuch Valenzuela', 'yhuaycuch', 'ce3ae197dd86341cbe2ed2ae9e30e145', 2, 1, b'1'),
(10, 'Aumbbel', 'Manrique', 'amo', '43e423ee04be24b417b0c5eb71ad4464', 1, 3, b'1'),
(9, 'demo', 'demo', 'demo', 'fe01ce2a7fbac8fafaed7c982a04e229', 2, 2, b'1'),
(8, 'Aumbbel', 'Manrique', 'aumbbel', 'ef6299c9e7fdae6d775819ce1e2620b8', 1, 3, b'1'),
(13, 'Beatriz', 'Manrique', 'bmanrique', '938bde16c106ec10453dcdf051fb0d49', 2, 1, b'1'),
(12, 'Pilar Maria', 'Mateo Quincho', 'pmateo', '787dab1236880babb61463fffd4bc784', 2, 1, b'1'),
(14, 'manrique Mendoza', 'Giordan Neil', 'Giordan', '0c873d95e9162fe77b3b1de9689ce403', 2, 1, b'1'),
(15, 'Beatriz', 'Manrique', 'betzabe', '96e6383126d8d4fd1a9112766d4b1fca', 2, 7, b'1'),
(16, 'Cardenas Pineda', 'Mariza', 'mariza', '351587c4bdae9b1ac951117ba9ae7685', 2, 1, b'1');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `caja`
--
ALTER TABLE `caja`
  ADD PRIMARY KEY (`idCaja`);

--
-- Indices de la tabla `Cliente`
--
ALTER TABLE `Cliente`
  ADD PRIMARY KEY (`idCliente`),
  ADD UNIQUE KEY `idCliente` (`idCliente`);

--
-- Indices de la tabla `Compras`
--
ALTER TABLE `Compras`
  ADD PRIMARY KEY (`idCompra`);

--
-- Indices de la tabla `desembolso`
--
ALTER TABLE `desembolso`
  ADD PRIMARY KEY (`idDesembolso`);

--
-- Indices de la tabla `DetalleReporte`
--
ALTER TABLE `DetalleReporte`
  ADD PRIMARY KEY (`idDetalleReporte`);

--
-- Indices de la tabla `PagoaCuenta`
--
ALTER TABLE `PagoaCuenta`
  ADD PRIMARY KEY (`idPago`);

--
-- Indices de la tabla `poder`
--
ALTER TABLE `poder`
  ADD PRIMARY KEY (`idPoder`);

--
-- Indices de la tabla `prestamo`
--
ALTER TABLE `prestamo`
  ADD PRIMARY KEY (`idPrestamo`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`idProducto`);

--
-- Indices de la tabla `reportes_producto`
--
ALTER TABLE `reportes_producto`
  ADD PRIMARY KEY (`idReporte`);

--
-- Indices de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  ADD PRIMARY KEY (`idSucursal`);

--
-- Indices de la tabla `tempo`
--
ALTER TABLE `tempo`
  ADD PRIMARY KEY (`idtempo`);

--
-- Indices de la tabla `tipoProceso`
--
ALTER TABLE `tipoProceso`
  ADD PRIMARY KEY (`idTipoProceso`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idUsuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `caja`
--
ALTER TABLE `caja`
  MODIFY `idCaja` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;
--
-- AUTO_INCREMENT de la tabla `Cliente`
--
ALTER TABLE `Cliente`
  MODIFY `idCliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=386;
--
-- AUTO_INCREMENT de la tabla `Compras`
--
ALTER TABLE `Compras`
  MODIFY `idCompra` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT de la tabla `desembolso`
--
ALTER TABLE `desembolso`
  MODIFY `idDesembolso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=536;
--
-- AUTO_INCREMENT de la tabla `DetalleReporte`
--
ALTER TABLE `DetalleReporte`
  MODIFY `idDetalleReporte` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT de la tabla `PagoaCuenta`
--
ALTER TABLE `PagoaCuenta`
  MODIFY `idPago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT de la tabla `poder`
--
ALTER TABLE `poder`
  MODIFY `idPoder` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT de la tabla `prestamo`
--
ALTER TABLE `prestamo`
  MODIFY `idPrestamo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=536;
--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `idProducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=539;
--
-- AUTO_INCREMENT de la tabla `reportes_producto`
--
ALTER TABLE `reportes_producto`
  MODIFY `idReporte` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=259;
--
-- AUTO_INCREMENT de la tabla `sucursal`
--
ALTER TABLE `sucursal`
  MODIFY `idSucursal` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT de la tabla `tempo`
--
ALTER TABLE `tempo`
  MODIFY `idtempo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT de la tabla `tipoProceso`
--
ALTER TABLE `tipoProceso`
  MODIFY `idTipoProceso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idUsuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
