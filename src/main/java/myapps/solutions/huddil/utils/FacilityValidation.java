package myapps.solutions.huddil.utils;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import javax.validation.Constraint;
import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import javax.validation.Payload;

import org.apache.http.util.TextUtils;

import myapps.solutions.huddil.model.Facility;
import myapps.solutions.huddil.utils.FacilityValidation.ValidateFacility;

@Target({ ElementType.TYPE })
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = ValidateFacility.class)
public @interface FacilityValidation {

	String message() default "";

	Class<?>[] groups() default {};

	Class<? extends Payload>[] payload() default {};

	public static class ValidateFacility implements ConstraintValidator<FacilityValidation, Object> {

		@Override
		public void initialize(FacilityValidation arg0) {

		}

		@Override
		public boolean isValid(Object obj, ConstraintValidatorContext context) {
			context.disableDefaultConstraintViolation();
			boolean isValid = true;
			if (obj == null)
				return false;
			if (obj instanceof Facility) {
				Facility facility = (Facility) obj;
				if (facility.isSave())
					return true;
				isValid = isValid && isValidText(facility.getCity(), "city", context);
				isValid = isValid && isValidText(facility.getFacilityType(), "facilityType", context);
				isValid = isValid && isValidText(facility.getLocality(), "locality", context);
				isValid = isValid && isValidText(facility.getDescription(), "description", context);
				isValid = isValid && isValidText(facility.getTitle(), "title", context);
				isValid = isValid && isValidText(facility.getContactNo(), "contactNo", context);
				isValid = isValid && isValidText(facility.getEmailId(), "emailId", context);
				isValid = isValid && isValidText(facility.getThumbnail(), "thumbnail", context);

				isValid = isValid && isValidNumber(facility.getUserPrefBySpUserId(), "spUserId", context);
				isValid = isValid && isValidNumber(facility.getCapacity(), "capacity", context);
				isValid = isValid && isValidNumber(facility.getSize(), "size", context);
				isValid = isValid && isValidNumber(facility.getStatus(), "status", context);

				isValid = isValid && isValidDouble(facility.getCostPerHour(), "costPerHour", context);
				isValid = isValid && isValidDouble(facility.getCostPerDay(), "costPerDay", context);
				isValid = isValid && isValidDouble(facility.getCostPerMonth(), "costPerMonth", context);

				if (facility.getFacilityCancellationCharges() == null) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("NotEmpty.facility.cancellationCharge")
							.addPropertyNode("cancellationCharge").addConstraintViolation();
				}
				if (facility.getLocation() == null) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("NotEmpty.facility.location")
							.addPropertyNode("location").addConstraintViolation();
				}

				int data = facility.getPaymnetType();
				if (facility.getFacilityType().equals("-1")) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("Values.facility.facilityType")
							.addPropertyNode("facilityType").addConstraintViolation();
				} else {
					if (facility.getFacilityType().equals("Co-Working Space")) {
						if (facility.getPaymnetType() != 2) {
							isValid = false;
							context.buildConstraintViolationWithTemplate("Values.facility.coWorkingPaymentType")
									.addPropertyNode("paymentType").addConstraintViolation();
						}
						if (facility.getCostPerHour() != 0) {
							isValid = false;
							context.buildConstraintViolationWithTemplate("Values.facility.costPerHour")
									.addPropertyNode("costPerHour").addConstraintViolation();
						}
					} else {
						if (data < 1 || data > 3) {
							isValid = false;
							context.buildConstraintViolationWithTemplate("Values.facility.paymentType")
									.addPropertyNode("paymentType").addConstraintViolation();
						}
					}
				}

				if (facility.getFacilityPhotos() == null || facility.getFacilityPhotos().isEmpty()) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("NotEmpty.facility.photos")
							.addPropertyNode("photos").addConstraintViolation();
				} else if (facility.getFacilityPhotos().size() < 3) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("Values.facility.photos")
							.addPropertyNode("photos").addConstraintViolation();
				}

				if (facility.getFacilityTimings() == null || facility.getFacilityTimings().isEmpty()) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("NotEmpty.facility.timing").addPropertyNode("timing")
							.addConstraintViolation();
				} else if (facility.getFacilityTimings().size() != 7) {
					isValid = false;
					context.buildConstraintViolationWithTemplate("Values.facility.timing").addPropertyNode("timing")
							.addConstraintViolation();
				}

			} else
				isValid = false;
			return isValid;
		}

		private boolean isValidText(String data, String field, ConstraintValidatorContext context) {
			if (TextUtils.isBlank(data)) {
				context.buildConstraintViolationWithTemplate("NotEmpty.facility." + field).addPropertyNode(field)
						.addConstraintViolation();
				return false;
			}
			return true;
		}

		private boolean isValidNumber(int data, String field, ConstraintValidatorContext context) {
			if (data < 0) {
				context.buildConstraintViolationWithTemplate("NotEmpty.facility." + field).addPropertyNode(field)
						.addConstraintViolation();
				return false;
			}
			return true;
		}

		private boolean isValidDouble(double data, String field, ConstraintValidatorContext context) {
			if (data < 0.0) {
				context.buildConstraintViolationWithTemplate("NotEmpty.facility." + field).addPropertyNode(field)
						.addConstraintViolation();
				return false;
			}
			return true;
		}
	}
}
