import { Box, Button, Divider, LinearProgress, Typography } from '@mui/material'
import React, {
  FC,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { useComment } from '../hooks/useComment'
import { useAuth } from '@/context/AuthProvider'
import { useAlerts, useSession } from '@/hooks'
import { Constantes, DEFAULT_LIMIT_PAGE } from '@/config/Constantes'
import { imprimir } from '@/utils/imprimir'
import { InterpreteMensajes, createComentariosSocket } from '@/utils'
import {
  ComentarioArchivoType,
  ComentarioReadType,
  ComentarioSubmitPayload,
  ComentarioUsuarioType,
} from '../types/comentario.type'
import { Icono } from '@/components/Icono'
import TipTapWithAvatar from './TipTapWithAvatar'
import CardComment, { type CardCommentProps } from './CardComment'
import { isLastPage } from '@/utils/fetch'
import { RolEnum } from '@/app/admin/(administracion)/nutricionistas/types/usuariosCRUDTypes'
import type { SimpleSocket } from '@/utils/websocket'

const sanitizeBaseUrl = (url: string) => url.replace(/\/$/, '')

const mapArchivoFromApi = (
  archivo: any,
  contexto: { historiaClinicaId?: string | null; comentarioId?: string | null }
): ComentarioArchivoType => {
  const id = String(
    archivo?.id ??
      archivo?.idArchivo ??
      archivo?.archivoId ??
      archivo?.uid ??
      `${archivo?.nombre ?? 'archivo'}-${Math.random()}`
  )

  const historiaClinicaId =
    contexto.historiaClinicaId ??
    archivo?.historiaClinicaId ??
    archivo?.historiaClinica?.id ??
    archivo?.historiaClinica ??
    archivo?.historiaId ??
    archivo?.idHistoriaClinica ??
    null

  const comentarioId =
    contexto.comentarioId ??
    archivo?.comentarioId ??
    archivo?.idComentario ??
    archivo?.comentario?.id ??
    null

  const baseUrl = Constantes.baseUrl ? sanitizeBaseUrl(Constantes.baseUrl) : ''

  const urlDescarga =
    archivo?.urlDescarga ??
    archivo?.url ??
    archivo?.enlace ??
    (historiaClinicaId && comentarioId && id
      ? `${baseUrl}/historia-clinica/${historiaClinicaId}/comentarios/${comentarioId}/archivos/${id}`
      : comentarioId && id
        ? `${baseUrl}/comentarios/${comentarioId}/archivos/${id}`
        : '')

  return {
    id,
    nombre:
      archivo?.nombre ??
      archivo?.nombreArchivo ??
      archivo?.titulo ??
      'Archivo adjunto',
    tipo: archivo?.tipo ?? archivo?.tipoMime ?? archivo?.mime ?? '',
    pesoBytes:
      archivo?.pesoBytes ??
      archivo?.peso ??
      archivo?.tamano ??
      archivo?.tamanio ??
      archivo?.size,
    urlDescarga,
    historiaClinicaId,
    comentarioId,
  }
}

const mapUsuarioFromApi = (usuario: any): ComentarioUsuarioType => ({
  idUsuario: String(usuario?.idUsuario ?? usuario?.id ?? ''),
  idUsuarioRol: usuario?.idUsuarioRol ?? usuario?.idRol ?? null,
  rol: usuario?.rol ?? usuario?.nombreRol ?? null,
  nombres: usuario?.nombres ?? '',
  primerApellido: usuario?.primerApellido ?? '',
  segundoApellido: usuario?.segundoApellido ?? null,
  urlFoto: usuario?.urlFoto ?? usuario?.foto ?? usuario?.fotoUrl ?? null,
})

const resolveHistoriaClinicaId = (
  comentario: any,
  historiaClinicaId?: string | null
): string | null =>
  historiaClinicaId ??
  comentario?.historiaClinicaId ??
  comentario?.historiaClinica?.id ??
  comentario?.historiaId ??
  comentario?.idHistoriaClinica ??
  null

const mapComentarioFromApi = (
  comentario: any,
  historiaClinicaId?: string | null
): ComentarioReadType => {
  const idComentario = String(
    comentario?.id ?? comentario?.idComentario ?? comentario?.comentarioId ?? ''
  )

  const historiaClinicaContexto = resolveHistoriaClinicaId(
    comentario,
    historiaClinicaId
  )

  return {
    id: idComentario,
    contenido: comentario?.contenido ?? '',
    fechaCreacion:
      comentario?.fechaCreacion ??
      comentario?.createdAt ??
      new Date().toISOString(),
    fechaModificacion:
      comentario?.fechaModificacion ?? comentario?.updatedAt ?? null,
    idComentarioPadre: comentario?.idComentarioPadre ?? null,
    usuario: mapUsuarioFromApi(comentario?.usuario ?? {}),
    archivos: (comentario?.archivos ?? []).map((archivo: any) =>
      mapArchivoFromApi(archivo, {
        historiaClinicaId: historiaClinicaContexto,
        comentarioId: idComentario,
      })
    ),
    respuestas: (comentario?.respuestas ?? []).map((respuesta: any) =>
      mapComentarioFromApi(respuesta, historiaClinicaContexto)
    ),
  }
}

const buildAdjuntosTemporales = (
  archivos: File[],
  contexto: { historiaClinicaId?: string | null; comentarioId?: string | null }
): ComentarioArchivoType[] =>
  archivos.map((archivo, index) => ({
    id: `temp-file-${index}-${archivo.name}`,
    nombre: archivo.name,
    tipo: archivo.type,
    pesoBytes: archivo.size,
    urlDescarga: '',
    historiaClinicaId: contexto.historiaClinicaId ?? null,
    comentarioId: contexto.comentarioId ?? null,
  }))

const buildNombreCompleto = (usuario: ComentarioUsuarioType) =>
  [usuario.nombres, usuario.primerApellido, usuario.segundoApellido]
    .filter((value) => value && value.trim() !== '')
    .join(' ')

const normalizeRoleKey = (rol?: string | null): string | undefined => {
  if (!rol) {
    return undefined
  }

  const trimmed = String(rol).trim()
  if (!trimmed) {
    return undefined
  }

  return trimmed.replace(/\s+/g, '_').toUpperCase()
}

const humanizeRoleLabel = (rol?: string | null): string | undefined => {
  if (!rol) {
    return undefined
  }

  const trimmed = String(rol).trim()
  if (!trimmed) {
    return undefined
  }

  const lower = trimmed.toLowerCase()
  if (lower === 'administrador') {
    return 'Administrador'
  }
  if (lower === 'nutricionista') {
    return 'Nutricionista'
  }
  if (lower === 'paciente') {
    return 'Paciente'
  }

  return trimmed
    .toLowerCase()
    .split(/[_\s]+/)
    .filter((part) => part.length > 0)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

interface SeccionComentariosProps {
  idHistoriaClinica?: string
}

const SeccionComentarios: FC<SeccionComentariosProps> = ({
  idHistoriaClinica,
}) => {
  const {
    comentarios,
    initData,
    agregarCommentario,
    actualizarComentario,
    eliminarComentario,
    responderComentario,
    actualizarRespuesta,
    eliminarRespuesta,
    adicionarComentarios,
    obtenerComentarioPorId,
  } = useComment()

  const { usuario, estaAutenticado, rolUsuario } = useAuth()

  const [openComment, setOpenComment] = useState<boolean>(false)
  const [loading, setLoading] = useState<boolean>(false)
  const [pagina, setPagina] = useState<number>(1)
  const [isLast, setIsLast] = useState<boolean>(false)
  const [total, setTotal] = useState<number>(0)

  const { Alerta } = useAlerts()
  const { sesionPeticion } = useSession()

  const socketRef = useRef<SimpleSocket | null>(null)
  const comentariosRef = useRef<ComentarioReadType[]>([])
  const accionesRef = useRef({
    agregarCommentario,
    responderComentario,
    actualizarComentario,
    actualizarRespuesta,
    eliminarComentario,
    eliminarRespuesta,
  })

  useEffect(() => {
    comentariosRef.current = comentarios
  }, [comentarios])

  useEffect(() => {
    accionesRef.current = {
      agregarCommentario,
      responderComentario,
      actualizarComentario,
      actualizarRespuesta,
      eliminarComentario,
      eliminarRespuesta,
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const nombres = usuario?.persona?.nombres ?? ''
  const primerApellido = usuario?.persona?.primerApellido ?? ''
  const segundoApellido = usuario?.persona?.segundoApellido ?? ''

  const usuarioLogged = useMemo<ComentarioUsuarioType>(
    () => ({
      idUsuario: usuario?.id ?? '',
      idUsuarioRol: usuario?.idRol ?? null,
      rol: rolUsuario?.rol ?? null,
      nombres,
      primerApellido,
      segundoApellido,
      urlFoto: usuario?.urlFoto ?? null,
    }),
    [
      usuario?.id,
      usuario?.idRol,
      usuario?.urlFoto,
      rolUsuario?.rol,
      nombres,
      primerApellido,
      segundoApellido,
    ]
  )

  const fullNameUserLogged = useMemo(
    () => buildNombreCompleto(usuarioLogged),
    [usuarioLogged]
  )

  const isAdmin = rolUsuario?.rol === RolEnum.ADMINISTRADOR

  const isOwner = useCallback(
    (idUsuario: string) => {
      return isAdmin || idUsuario === (usuario?.id ?? '')
    },
    [isAdmin, usuario?.id]
  )

  const handleValidationError = useCallback(
    (mensaje: string) => {
      Alerta({ mensaje, variant: 'warning' })
    },
    [Alerta]
  )

  const obtenerComentariosPeticion = useCallback(
    async (paginaConsulta: number) => {
      if (!idHistoriaClinica) {
        return [] as ComentarioReadType[]
      }

      try {
        setLoading(true)
        const respuesta = await sesionPeticion({
          url: `${Constantes.baseUrl}/historia-clinica/${idHistoriaClinica}/comentarios`,
          params: {
            pagina: paginaConsulta,
            limite: DEFAULT_LIMIT_PAGE,
          },
        })

        const totalItems = respuesta?.datos?.total ?? 0
        setTotal(totalItems)
        setIsLast(isLastPage(paginaConsulta, DEFAULT_LIMIT_PAGE, totalItems))

        return (respuesta?.datos?.filas ?? []).map((comentario: any) =>
          mapComentarioFromApi(comentario, idHistoriaClinica)
        )
      } catch (error) {
        imprimir(`Error al obtener comentarios`, error)
        const mensaje = InterpreteMensajes(error)
        Alerta({ mensaje, variant: 'error' })
        throw new Error(mensaje)
      } finally {
        setLoading(false)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [idHistoriaClinica]
  )

  const guardarComentarioPeticion = useCallback(
    async (comentario: ComentarioSubmitPayload) => {
      if (!idHistoriaClinica) {
        throw new Error('La historia clínica no está definida')
      }

      try {
        setLoading(true)
        const formData = new FormData()
        formData.append('contenido', comentario.contenido)
        comentario.archivos.forEach((archivo) => {
          formData.append('archivos', archivo)
        })

        const respuesta = await sesionPeticion({
          url: `${Constantes.baseUrl}/historia-clinica/${idHistoriaClinica}/comentarios`,
          method: 'post',
          body: formData,
        })

        return mapComentarioFromApi(respuesta?.datos ?? {}, idHistoriaClinica)
      } catch (error) {
        imprimir(`Error al crear comentario`, error)
        const mensaje = InterpreteMensajes(error)
        Alerta({ mensaje, variant: 'error' })
        throw new Error(mensaje)
      } finally {
        setLoading(false)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [idHistoriaClinica]
  )

  const responderComentarioPeticion = useCallback(
    async (idComentario: string, comentario: ComentarioSubmitPayload) => {
      try {
        setLoading(true)
        const formData = new FormData()
        formData.append('contenido', comentario.contenido)
        comentario.archivos.forEach((archivo) => {
          formData.append('archivos', archivo)
        })

        const respuesta = await sesionPeticion({
          url: `${Constantes.baseUrl}/comentarios/${idComentario}/reply`,
          method: 'post',
          body: formData,
        })

        return mapComentarioFromApi(respuesta?.datos ?? {}, idHistoriaClinica)
      } catch (error) {
        imprimir(`Error al responder comentario`, error)
        const mensaje = InterpreteMensajes(error)
        Alerta({ mensaje, variant: 'error' })
        throw new Error(mensaje)
      } finally {
        setLoading(false)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [idHistoriaClinica]
  )

  const editarComentarioPeticion = useCallback(
    async (idComentario: string, comentario: { contenido: string }) => {
      try {
        setLoading(true)
        const respuesta = await sesionPeticion({
          url: `${Constantes.baseUrl}/comentarios/${idComentario}`,
          method: 'patch',
          body: comentario,
        })

        const datos = respuesta?.datos
        return datos
          ? mapComentarioFromApi(datos, idHistoriaClinica)
          : { ...comentario, id: idComentario }
      } catch (error) {
        imprimir(`Error al editar comentario`, error)
        const mensaje = InterpreteMensajes(error)
        Alerta({ mensaje, variant: 'error' })
        throw new Error(mensaje)
      } finally {
        setLoading(false)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [idHistoriaClinica]
  )

  const inactivarComentarioPeticion = useCallback(
    async (idComentario: string) => {
      try {
        setLoading(true)
        await sesionPeticion({
          url: `${Constantes.baseUrl}/comentarios/${idComentario}/inactivar`,
          method: 'patch',
        })
      } catch (error) {
        imprimir(`Error al inactivar comentario`, error)
        const mensaje = InterpreteMensajes(error)
        Alerta({ mensaje, variant: 'error' })
        throw new Error(mensaje)
      } finally {
        setLoading(false)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  const handleAdd = useCallback(
    async (payload: ComentarioSubmitPayload) => {
      const tempId = `temp-${Date.now()}`
      const comentarioTemporal: ComentarioReadType = {
        id: tempId,
        contenido: payload.contenido,
        fechaCreacion: new Date().toISOString(),
        usuario: usuarioLogged,
        archivos: buildAdjuntosTemporales(payload.archivos, {
          historiaClinicaId: idHistoriaClinica ?? null,
          comentarioId: tempId,
        }),
        respuestas: [],
        idComentarioPadre: null,
        fechaModificacion: null,
      }

      agregarCommentario(comentarioTemporal)
      setOpenComment(false)
      setTotal((prevTotal) => prevTotal + 1)

      try {
        const nuevoComentario = await guardarComentarioPeticion(payload)
        if (nuevoComentario) {
          actualizarComentario(tempId, {
            ...nuevoComentario,
            id: nuevoComentario.id ?? tempId,
          })
        }
      } catch (error) {
        eliminarComentario(tempId)
        setTotal((prevTotal) => Math.max(prevTotal - 1, 0))
        throw error
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [usuarioLogged, idHistoriaClinica]
  )

  const handleEdit = useCallback(
    async (idComentario: string, payload: ComentarioSubmitPayload) => {
      const respuesta = await editarComentarioPeticion(idComentario, {
        contenido: payload.contenido,
      })

      actualizarComentario(idComentario, {
        ...respuesta,
        contenido: payload.contenido,
        fechaModificacion:
          (respuesta as ComentarioReadType).fechaModificacion ??
          new Date().toISOString(),
      })
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  const handleReply = useCallback(
    async (idComentario: string, payload: ComentarioSubmitPayload) => {
      const tempId = `temp-${Date.now()}`
      const respuestaTemporal: ComentarioReadType = {
        id: tempId,
        contenido: payload.contenido,
        fechaCreacion: new Date().toISOString(),
        usuario: usuarioLogged,
        archivos: buildAdjuntosTemporales(payload.archivos, {
          historiaClinicaId: idHistoriaClinica ?? null,
          comentarioId: tempId,
        }),
        respuestas: [],
        idComentarioPadre: idComentario,
        fechaModificacion: null,
      }

      responderComentario(idComentario, respuestaTemporal)

      try {
        const nuevaRespuesta = await responderComentarioPeticion(
          idComentario,
          payload
        )
        if (nuevaRespuesta) {
          actualizarComentario(tempId, {
            ...nuevaRespuesta,
            id: nuevaRespuesta.id ?? tempId,
          })
        }
      } catch (error) {
        eliminarRespuesta(idComentario, tempId)
        throw error
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [usuarioLogged, idHistoriaClinica]
  )

  const handleEditRespuesta = useCallback(
    async (
      idComentario: string,
      idRespuesta: string,
      payload: ComentarioSubmitPayload
    ) => {
      const respuesta = await editarComentarioPeticion(idRespuesta, {
        contenido: payload.contenido,
      })

      const fechaModificacion =
        (respuesta as ComentarioReadType).fechaModificacion ??
        new Date().toISOString()

      actualizarRespuesta(idComentario, idRespuesta, {
        ...respuesta,
        contenido: payload.contenido,
        fechaModificacion,
      })
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  const handleEliminar = useCallback(
    async (idComentario: string) => {
      await inactivarComentarioPeticion(idComentario)
      eliminarComentario(idComentario)
      setTotal((prevTotal) => Math.max(prevTotal - 1, 0))
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  const handleEliminarRespuesta = useCallback(
    async (idComentario: string, idRespuesta: string) => {
      await inactivarComentarioPeticion(idRespuesta)
      eliminarRespuesta(idComentario, idRespuesta)
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )

  useEffect(() => {
    if (!idHistoriaClinica || !estaAutenticado) {
      return
    }

    setPagina(1)

    const initialize = async () => {
      try {
        const initialData = await obtenerComentariosPeticion(1)
        initData(initialData)
      } catch {
        initData([])
      }
    }

    void initialize()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [estaAutenticado, idHistoriaClinica])

  useEffect(() => {
    if (pagina === 1) {
      return
    }

    const handleShowMore = async () => {
      try {
        const newComentarios = await obtenerComentariosPeticion(pagina)
        adicionarComentarios(newComentarios)
      } catch {
        // El error ya se notificó en la llamada
      }
    }

    void handleShowMore()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pagina])

  useEffect(() => {
    if (!idHistoriaClinica || !estaAutenticado) {
      return
    }

    const socket = createComentariosSocket()
    if (!socket) {
      return
    }

    socketRef.current = socket

    const applyComentarioCreado = (comentario: ComentarioReadType) => {
      if (!comentario.id) {
        return
      }

      const existe = comentariosRef.current.some(
        (item) => item.id === comentario.id
      )

      if (comentario.idComentarioPadre) {
        accionesRef.current.responderComentario(
          comentario.idComentarioPadre,
          comentario
        )
      } else {
        accionesRef.current.agregarCommentario(comentario)
        if (!existe) {
          setTotal((prevTotal) => prevTotal + 1)
        }
      }
    }

    const applyComentarioActualizado = (comentario: ComentarioReadType) => {
      if (!comentario.id) {
        return
      }

      if (comentario.idComentarioPadre) {
        accionesRef.current.actualizarRespuesta(
          comentario.idComentarioPadre,
          comentario.id,
          comentario
        )
      } else {
        accionesRef.current.actualizarComentario(comentario.id, comentario)
      }
    }

    const applyComentarioEliminado = (comentarioId: string) => {
      if (!comentarioId) {
        return
      }

      const comentarioActual = obtenerComentarioPorId(comentarioId)
      if (!comentarioActual) {
        return
      }

      if (comentarioActual.idComentarioPadre) {
        accionesRef.current.eliminarRespuesta(
          comentarioActual.idComentarioPadre,
          comentarioId
        )
      } else {
        accionesRef.current.eliminarComentario(comentarioId)
        setTotal((prevTotal) => (prevTotal > 0 ? prevTotal - 1 : prevTotal))
      }
    }

    const handleComentarioCambio = (payload: any) => {
      const tipo = String(payload?.tipo ?? '').toLowerCase()
      const historiaEvento = String(
        payload?.historiaClinicaId ??
          payload?.historiaId ??
          payload?.idHistoriaClinica ??
          ''
      )

      if (
        historiaEvento &&
        idHistoriaClinica &&
        historiaEvento !== String(idHistoriaClinica)
      ) {
        return
      }

      const comentarioPayload = payload?.comentario ?? payload?.dato ?? payload

      if (tipo === 'creado') {
        const comentario = mapComentarioFromApi(
          comentarioPayload,
          historiaEvento || idHistoriaClinica
        )
        applyComentarioCreado(comentario)
        return
      }

      if (tipo === 'actualizado') {
        const comentario = mapComentarioFromApi(
          comentarioPayload,
          historiaEvento || idHistoriaClinica
        )
        applyComentarioActualizado(comentario)
        return
      }

      if (tipo === 'eliminado') {
        const comentarioId = String(
          payload?.comentarioId ??
            payload?.id ??
            comentarioPayload?.id ??
            comentarioPayload?.comentarioId ??
            ''
        )
        applyComentarioEliminado(comentarioId)
        return
      }

      if (comentarioPayload?.id) {
        // Fallback para compatibilidad cuando no se envía el tipo explícito
        const comentario = mapComentarioFromApi(
          comentarioPayload,
          historiaEvento || idHistoriaClinica
        )

        if (comentarioPayload?.eliminado) {
          applyComentarioEliminado(comentario.id)
        } else if (comentarioPayload?.idComentarioPadre) {
          applyComentarioActualizado(comentario)
        } else {
          applyComentarioCreado(comentario)
        }
      }
    }

    socket.on('comentario:cambio', handleComentarioCambio)

    socket.emit('joinHistoriaClinica', { historiaClinicaId: idHistoriaClinica })

    return () => {
      socket.emit('leaveHistoriaClinica', {
        historiaClinicaId: idHistoriaClinica,
      })
      socket.off('comentario:cambio', handleComentarioCambio)
      socket.disconnect()
      socketRef.current = null
    }
  }, [estaAutenticado, idHistoriaClinica, obtenerComentarioPorId])

  const buildMenuItemActions = (handleDelete: () => void) => [
    {
      key: 'eliminar',
      label: 'Eliminar',
      icon: <Icono fontSize="small">delete</Icono>,
      onClick: handleDelete,
    },
  ]

  const buildReplyCard = useCallback(
    (
      comentarioPadreId: string,
      respuesta: ComentarioReadType
    ): CardCommentProps => {
      const esPropietario = isOwner(respuesta.usuario.idUsuario)

      return {
        owner: {
          fullName: buildNombreCompleto(respuesta.usuario),
          avatarName: respuesta.usuario.urlFoto ?? undefined,
          roleLabel: humanizeRoleLabel(respuesta.usuario.rol),
          roleKey: normalizeRoleKey(respuesta.usuario.rol),
        },
        userReply: {
          fullName: fullNameUserLogged,
          avatarName: usuarioLogged.urlFoto ?? undefined,
        },
        text: respuesta.contenido,
        date: respuesta.fechaCreacion,
        attachments: respuesta.archivos ?? [],
        isOwnMessage: esPropietario,
        isEdited: Boolean(
          respuesta.fechaModificacion &&
            respuesta.fechaModificacion !== respuesta.fechaCreacion
        ),
        onEdit:
          esPropietario || isAdmin
            ? (payload) =>
                handleEditRespuesta(comentarioPadreId, respuesta.id, payload)
            : undefined,
        menuItemActions:
          esPropietario || isAdmin
            ? buildMenuItemActions(() =>
                handleEliminarRespuesta(comentarioPadreId, respuesta.id)
              )
            : undefined,
        replies: respuesta.respuestas?.map((child) =>
          buildReplyCard(respuesta.id, child)
        ),
        maxFiles: Constantes.chatMaxFiles,
        maxFileSizeMB: Constantes.chatMaxFileSizeMB,
        onValidationError: handleValidationError,
      }
    },
    [
      fullNameUserLogged,
      usuarioLogged,
      isOwner,
      isAdmin,
      handleEditRespuesta,
      handleEliminarRespuesta,
      handleValidationError,
    ]
  )

  return (
    <Box my={2} pr={1}>
      {/* Cabecera de seccion */}
      <Box display={'flex'} justifyContent={'space-between'} pb={1}>
        <Typography variant="body1" fontWeight="medium">
          Discusiones
        </Typography>
        <Box display={'flex'} alignItems={'center'} gap={1}>
          <Typography variant="body2" color="text.secondary">
            {total}
          </Typography>
          <Icono fontSize="small" sx={{ color: 'text.secondary' }}>
            chat
          </Icono>
          <Box width={8} />
          <Button
            size="small"
            onClick={() => {
              setOpenComment((prevOpen) => !prevOpen)
            }}
          >
            Comentar
          </Button>
        </Box>
      </Box>
      <Divider />
      {<LinearProgress sx={{ opacity: loading ? 1 : 0 }} />}
      <Box height={16} />
      {/* Card para comentar */}
      {openComment && (
        <TipTapWithAvatar
          fullName={fullNameUserLogged}
          avatarName={usuarioLogged.urlFoto ?? undefined}
          maxFiles={Constantes.chatMaxFiles}
          maxFileSizeMB={Constantes.chatMaxFileSizeMB}
          onValidationError={handleValidationError}
          onAccept={{
            label: 'Comentar',
            execute: async (payload) => {
              await handleAdd(payload)
            },
          }}
          onCancel={{
            label: 'Cancelar',
            execute: () => {
              setOpenComment(false)
            },
          }}
        />
      )}
      {/* lista de comentarios */}
      {comentarios.map((c) => (
        <CardComment
          key={`card-comment-${c.id}`}
          owner={{
            fullName: buildNombreCompleto(c.usuario),
            avatarName: c.usuario.urlFoto ?? undefined,
            roleLabel: humanizeRoleLabel(c.usuario.rol),
            roleKey: normalizeRoleKey(c.usuario.rol),
          }}
          userReply={{
            fullName: fullNameUserLogged,
            avatarName: usuarioLogged.urlFoto ?? undefined,
          }}
          text={c.contenido}
          date={c.fechaCreacion}
          attachments={c.archivos ?? []}
          isOwnMessage={isOwner(c.usuario.idUsuario)}
          isEdited={Boolean(
            c.fechaModificacion && c.fechaModificacion !== c.fechaCreacion
          )}
          onEdit={
            isOwner(c.usuario.idUsuario) || isAdmin
              ? (payload) => handleEdit(c.id, payload)
              : undefined
          }
          onReply={(payload) => handleReply(c.id, payload)}
          menuItemActions={
            isOwner(c.usuario.idUsuario) || isAdmin
              ? buildMenuItemActions(() => handleEliminar(c.id))
              : undefined
          }
          replies={c.respuestas?.map((res) => buildReplyCard(c.id, res))}
          maxFiles={Constantes.chatMaxFiles}
          maxFileSizeMB={Constantes.chatMaxFileSizeMB}
          onValidationError={handleValidationError}
        />
      ))}
      {/* Paginacion */}
      {!isLast && (
        <Box display={'flex'} justifyContent={'center'}>
          <Button
            variant="outlined"
            size="small"
            color="secondary"
            sx={{ borderRadius: 8, px: 3 }}
            onClick={() => {
              setPagina((prevPagina) => prevPagina + 1)
            }}
          >
            Mostrar más
          </Button>
        </Box>
      )}
    </Box>
  )
}

export default SeccionComentarios
