package myapps.solutions.huddil.model;

import java.util.ArrayList;
import java.util.List;

public class ValidationErrorDTO {
	private List<FieldErrorDTO> fieldErrors = new ArrayList<>();

	public ValidationErrorDTO() {

	}

	public void addFieldError(String path, String message) {
		FieldErrorDTO error = new FieldErrorDTO(path, message);
		fieldErrors.add(error);
	}

	public List<FieldErrorDTO> getFieldErrors() {
		return fieldErrors;
	}
}

class FieldErrorDTO {

	private String field;

	private String message;

	public FieldErrorDTO(String field, String message) {
		this.field = field;
		this.message = message;
	}

	public String getField() {
		return field;
	}

	public String getMessage() {
		return message;
	}
}