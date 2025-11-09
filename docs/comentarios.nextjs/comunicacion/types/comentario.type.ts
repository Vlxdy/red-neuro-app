export interface ComentarioCRUDType {
  id?: string
  contenido: string
}

export interface ComentarioUsuarioType {
  idUsuario: string
  idUsuarioRol?: string | null
  rol?: string | null
  nombres: string
  primerApellido: string
  segundoApellido?: string | null
  urlFoto?: string | null
}

export interface ComentarioArchivoType {
  id: string
  nombre: string
  tipo: string
  pesoBytes?: number
  urlDescarga: string
  historiaClinicaId?: string | null
  comentarioId?: string | null
}

export type ComentarioReadType = ComentarioCRUDType & {
  id: string
  fechaCreacion: string
  fechaModificacion?: string | null
  idComentarioPadre?: string | null
  usuario: ComentarioUsuarioType
  archivos?: ComentarioArchivoType[]
  respuestas?: ComentarioReadType[]
}

export interface ComentarioSubmitPayload {
  contenido: string
  archivos: File[]
}
